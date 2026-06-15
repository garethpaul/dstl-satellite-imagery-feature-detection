import configparser
import errno
import logging
import math
import os
import secrets
import stat
import zipfile
from urllib.parse import parse_qs, urlparse

import requests


BASE_DOWNLOAD_URL = (
    "https://www.kaggle.com/account/login?"
    "ReturnUrl=/c/dstl-satellite-imagery-feature-detection/download/"
)
DATA_FILES = [
    "sample_submission.csv.zip",
    "grid_sizes.csv.zip",
    "sixteen_band.zip",
    "three_band.zip",
    "train_geojson_v3.zip",
    "train_wkt_v4.csv.zip",
]
ALLOWED_DATA_FILES = set(DATA_FILES)
DEFAULT_TIMEOUT = (10, 60)
CHUNK_SIZE = 1024 * 1024
DEFAULT_MAX_DOWNLOAD_BYTES = 25 * 1024 * 1024 * 1024
DEFAULT_MAX_EXTRACTED_BYTES = 100 * 1024 * 1024 * 1024
DEFAULT_MAX_ARCHIVE_MEMBERS = 100_000
ALLOWED_DOWNLOAD_HOSTS = {"kaggle.com", "www.kaggle.com"}


class KaggleCredentialsError(RuntimeError):
    pass


def credentials_path():
    return os.path.join(os.path.dirname(os.path.realpath(__file__)), "kaggle_credentials.ini")


def load_credentials(path=None):
    path = path or credentials_path()
    config = configparser.ConfigParser()

    if not config.read(path):
        raise KaggleCredentialsError(
            "Kaggle credentials file not found. Create kaggle_credentials.ini locally."
        )

    try:
        credentials = {
            "UserName": config["KAGGLE"]["login"],
            "Password": config["KAGGLE"]["password"],
        }
    except KeyError as exc:
        raise KaggleCredentialsError(
            "kaggle_credentials.ini must define [KAGGLE] login and password."
        ) from exc

    return normalize_credentials(credentials)


def normalize_credentials(credentials):
    try:
        login = credentials["UserName"].strip()
        password = credentials["Password"].strip()
    except (KeyError, AttributeError) as exc:
        raise KaggleCredentialsError(
            "Kaggle credentials must include UserName and Password."
        ) from exc

    if not login or not password:
        raise KaggleCredentialsError("Kaggle login and password must not be empty.")

    return {"UserName": login, "Password": password}


def is_positive_timeout_value(value):
    return (
        isinstance(value, (int, float))
        and not isinstance(value, bool)
        and math.isfinite(value)
        and value > 0
    )


def normalize_timeout(timeout):
    if is_positive_timeout_value(timeout):
        return timeout

    if (
        isinstance(timeout, tuple)
        and len(timeout) == 2
        and all(is_positive_timeout_value(value) for value in timeout)
    ):
        return timeout

    raise ValueError("Download timeout must be a positive number or (connect, read) pair.")


def normalize_positive_integer(value, label):
    if isinstance(value, int) and not isinstance(value, bool) and value > 0:
        return value
    raise ValueError(f"{label} must be a positive integer.")


def load_and_unzip_data(
    output_dir=None,
    credentials_file=None,
    timeout=DEFAULT_TIMEOUT,
    max_download_bytes=DEFAULT_MAX_DOWNLOAD_BYTES,
    max_extracted_bytes=DEFAULT_MAX_EXTRACTED_BYTES,
    max_archive_members=DEFAULT_MAX_ARCHIVE_MEMBERS,
):
    output_dir = output_dir or os.getcwd()
    credentials = load_credentials(credentials_file)

    logging.info("Start loading files ...")
    for filename in DATA_FILES:
        download_url(
            BASE_DOWNLOAD_URL + filename,
            output_dir=output_dir,
            credentials=credentials,
            timeout=timeout,
            max_download_bytes=max_download_bytes,
        )

    logging.info("Extracting files")
    for filename in DATA_FILES:
        if filename.endswith(".zip"):
            unzip(
                os.path.join(output_dir, filename),
                output_dir=output_dir,
                max_extracted_bytes=max_extracted_bytes,
                max_archive_members=max_archive_members,
            )


def filename_from_url(url):
    parsed_url = urlparse(url)
    return_url = parse_qs(parsed_url.query).get("ReturnUrl", [""])[0]
    filename = os.path.basename(return_url or parsed_url.path)
    if not filename:
        raise ValueError("Download URL must end with a filename.")
    return filename


def require_https_url(url):
    parsed_url = urlparse(url)
    if parsed_url.scheme.lower() != "https":
        raise ValueError("Download URL must use HTTPS.")
    if parsed_url.hostname not in ALLOWED_DOWNLOAD_HOSTS:
        raise ValueError("Download URL must use a Kaggle host.")
    if parsed_url.username or parsed_url.password:
        raise ValueError("Download URL must not include embedded credentials.")


def require_allowed_data_file(filename):
    if filename not in ALLOWED_DATA_FILES:
        raise ValueError("Download filename must be in the configured DSTL data file list.")


def require_valid_zip_file(source):
    try:
        with zipfile.ZipFile(source, "r") as zip_ref:
            if not zip_ref.infolist():
                raise ValueError("Downloaded file must be a non-empty ZIP archive.")
    except (OSError, zipfile.BadZipFile, zipfile.LargeZipFile) as exc:
        raise ValueError("Downloaded file must be a valid ZIP archive.") from exc


def download_url(
    url,
    output_dir=None,
    timeout=DEFAULT_TIMEOUT,
    session=None,
    credentials=None,
    credentials_file=None,
    max_download_bytes=DEFAULT_MAX_DOWNLOAD_BYTES,
):
    require_https_url(url)
    timeout = normalize_timeout(timeout)
    max_download_bytes = normalize_positive_integer(max_download_bytes, "Maximum download size")

    filename = filename_from_url(url)
    require_allowed_data_file(filename)
    output_root = os.path.abspath(output_dir or os.getcwd())
    filepath = os.path.join(output_root, filename)
    partial_name = filename + ".part"
    root_fd = open_download_root(output_root)
    try:
        cached_fd = open_cached_download(root_fd, filename)
        if cached_fd is not None:
            with os.fdopen(cached_fd, "rb") as handle:
                require_valid_zip_file(handle)
            require_download_root_identity(output_root, root_fd)
            logging.warning("File %s exists", filepath)
            return filepath

        try:
            os.unlink(partial_name, dir_fd=root_fd)
        except FileNotFoundError:
            pass

        credentials = (
            normalize_credentials(credentials)
            if credentials is not None
            else load_credentials(credentials_file)
        )
        client = session or requests
        response = client.post(url, data=credentials, stream=True, timeout=timeout)
        published_final = False
        try:
            response.raise_for_status()
            require_download_root_identity(output_root, root_fd)

            content_length = response.headers.get("Content-Length")
            if content_length is not None:
                try:
                    declared_size = int(content_length)
                except ValueError as exc:
                    raise ValueError("Download Content-Length must be an integer.") from exc
                if declared_size < 0 or declared_size > max_download_bytes:
                    raise ValueError("Download exceeds the configured size limit.")

            logging.info("Load file %s", filename)
            downloaded_bytes = 0
            partial_fd = os.open(
                partial_name,
                os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                0o600,
                dir_fd=root_fd,
            )
            with os.fdopen(partial_fd, "w+b") as handle:
                for chunk in response.iter_content(chunk_size=CHUNK_SIZE):
                    if chunk:
                        downloaded_bytes += len(chunk)
                        if downloaded_bytes > max_download_bytes:
                            raise ValueError("Download exceeds the configured size limit.")
                        handle.write(chunk)
                handle.flush()
                os.fsync(handle.fileno())
                handle.seek(0)
                require_valid_zip_file(handle)

            require_download_root_identity(output_root, root_fd)
            os.link(
                partial_name,
                filename,
                src_dir_fd=root_fd,
                dst_dir_fd=root_fd,
            )
            published_final = True
            os.unlink(partial_name, dir_fd=root_fd)
        except Exception:
            if published_final:
                try:
                    os.unlink(filename, dir_fd=root_fd)
                except FileNotFoundError:
                    pass
            try:
                os.unlink(partial_name, dir_fd=root_fd)
            except FileNotFoundError:
                pass
            raise
        finally:
            close = getattr(response, "close", None)
            if close:
                close()

        logging.info("FINISH file %s", filename)
        logging.info("File size: %d kb", os.stat(filename, dir_fd=root_fd).st_size)
        return filepath
    finally:
        os.close(root_fd)


def safe_zip_members(
    zip_ref,
    output_dir,
    max_extracted_bytes=DEFAULT_MAX_EXTRACTED_BYTES,
    max_archive_members=DEFAULT_MAX_ARCHIVE_MEMBERS,
):
    output_root = os.path.abspath(output_dir)
    max_extracted_bytes = normalize_positive_integer(max_extracted_bytes, "Maximum extracted size")
    max_archive_members = normalize_positive_integer(
        max_archive_members, "Maximum archive member count"
    )
    members = zip_ref.infolist()

    if len(members) > max_archive_members:
        raise ValueError("Zip archive exceeds the configured member limit.")

    total_size = sum(member.file_size for member in members)
    if total_size > max_extracted_bytes:
        raise ValueError("Zip archive exceeds the configured extracted size limit.")

    seen_targets = set()
    file_targets = set()
    required_directories = set()
    for member in members:
        if stat.S_ISLNK(member.external_attr >> 16):
            raise ValueError("Refusing to extract zip symlink member.")
        target_path = os.path.abspath(os.path.join(output_root, member.filename))
        if os.path.commonpath((output_root, target_path)) != output_root:
            raise ValueError("Refusing to extract zip member outside output directory.")
        target_key = os.path.normcase(target_path)
        if target_key in seen_targets:
            raise ValueError("Refusing to extract zip members with colliding target paths.")
        seen_targets.add(target_key)

        relative_parts = [
            part
            for part in os.path.relpath(target_path, output_root).split(os.sep)
            if part not in ("", ".")
        ]
        parent_path = output_root
        for part in relative_parts[:-1]:
            parent_path = os.path.join(parent_path, part)
            parent_key = os.path.normcase(parent_path)
            if parent_key in file_targets:
                raise ValueError(
                    "Refusing to extract zip members with file and directory prefix collisions."
                )
            required_directories.add(parent_key)

        if member.is_dir():
            required_directories.add(target_key)
        else:
            if target_key in required_directories:
                raise ValueError(
                    "Refusing to extract zip members with file and directory prefix collisions."
                )
            file_targets.add(target_key)

        current_path = output_root
        target_parts = os.path.relpath(target_path, output_root).split(os.sep)
        for index, part in enumerate(target_parts):
            current_path = os.path.join(current_path, part)
            if os.path.islink(current_path):
                raise ValueError("Refusing to extract through an existing symlink.")
            if not os.path.lexists(current_path):
                continue

            must_be_directory = index < len(target_parts) - 1 or member.is_dir()
            if must_be_directory != os.path.isdir(current_path):
                raise ValueError(
                    "Refusing to extract through an existing destination type collision."
                )
        yield member


def require_secure_descriptor_support():
    if (
        not hasattr(os, "O_DIRECTORY")
        or not hasattr(os, "O_NOFOLLOW")
        or os.open not in os.supports_dir_fd
        or os.mkdir not in os.supports_dir_fd
        or os.unlink not in os.supports_dir_fd
    ):
        raise RuntimeError("Secure descriptor-relative filesystem operations are unavailable.")


def require_secure_download_support():
    require_secure_descriptor_support()
    if os.link not in os.supports_dir_fd:
        raise RuntimeError("Secure descriptor-relative download publication is unavailable.")


def require_secure_extraction_support():
    require_secure_descriptor_support()
    if os.rename not in os.supports_dir_fd:
        raise RuntimeError("Secure descriptor-relative archive publication is unavailable.")


def open_download_root(output_root):
    require_secure_download_support()
    try:
        return open_output_root(output_root)
    except (OSError, ValueError) as exc:
        raise ValueError("Refusing to use a raced output root.") from exc


def require_download_root_identity(output_root, root_fd):
    try:
        path_stat = os.stat(output_root, follow_symlinks=False)
    except OSError as exc:
        raise ValueError("Refusing to use a raced output root.") from exc
    descriptor_stat = os.fstat(root_fd)
    if not stat.S_ISDIR(path_stat.st_mode) or (
        path_stat.st_dev,
        path_stat.st_ino,
    ) != (descriptor_stat.st_dev, descriptor_stat.st_ino):
        raise ValueError("Refusing to use a raced output root.")


def open_cached_download(root_fd, filename):
    try:
        cached_fd = os.open(
            filename,
            os.O_RDONLY | os.O_NOFOLLOW,
            dir_fd=root_fd,
        )
    except FileNotFoundError:
        return None
    except OSError as exc:
        if exc.errno == errno.ELOOP:
            raise ValueError("Existing download path must be a regular non-symlink file.") from exc
        raise

    if not stat.S_ISREG(os.fstat(cached_fd).st_mode):
        os.close(cached_fd)
        raise ValueError("Existing download path must be a regular non-symlink file.")
    return cached_fd


def open_extraction_directory(parent_fd, component):
    flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
    try:
        return os.open(component, flags, dir_fd=parent_fd)
    except FileNotFoundError:
        try:
            os.mkdir(component, mode=0o700, dir_fd=parent_fd)
        except FileExistsError:
            pass
        try:
            return os.open(component, flags, dir_fd=parent_fd)
        except OSError as exc:
            if exc.errno in (errno.ELOOP, errno.ENOTDIR):
                raise ValueError("Refusing to extract through a raced destination path.") from exc
            raise
    except OSError as exc:
        if exc.errno in (errno.ELOOP, errno.ENOTDIR):
            raise ValueError("Refusing to extract through a raced destination path.") from exc
        raise


def member_path_parts(member, output_root):
    target_path = os.path.abspath(os.path.join(output_root, member.filename))
    relative_path = os.path.relpath(target_path, output_root)
    return [part for part in relative_path.split(os.sep) if part not in ("", ".")]


def open_member_parent(root_fd, parent_parts):
    current_fd = os.dup(root_fd)
    try:
        for part in parent_parts:
            child_fd = open_extraction_directory(current_fd, part)
            os.close(current_fd)
            current_fd = child_fd
        return current_fd
    except Exception:
        os.close(current_fd)
        raise


def open_output_root(output_root):
    if not os.path.isabs(output_root):
        raise ValueError("Extraction output root must be absolute.")

    filesystem_root_fd = os.open(
        os.path.sep,
        os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
    )
    try:
        root_parts = [part for part in output_root.split(os.path.sep) if part]
        return open_member_parent(filesystem_root_fd, root_parts)
    finally:
        os.close(filesystem_root_fd)


def extract_zip_member(zip_ref, member, output_root, root_fd):
    parts = member_path_parts(member, output_root)
    if not parts:
        return

    if member.is_dir():
        directory_fd = open_member_parent(root_fd, parts)
        os.close(directory_fd)
        return

    parent_fd = open_member_parent(root_fd, parts[:-1])
    temporary_name = ".{0}.{1}.part".format(parts[-1], secrets.token_hex(8))
    temporary_fd = None
    try:
        temporary_fd = os.open(
            temporary_name,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
            0o600,
            dir_fd=parent_fd,
        )
        with zip_ref.open(member, "r") as source, os.fdopen(temporary_fd, "wb") as target:
            temporary_fd = None
            while True:
                chunk = source.read(CHUNK_SIZE)
                if not chunk:
                    break
                target.write(chunk)
            target.flush()
            os.fsync(target.fileno())

        os.replace(
            temporary_name,
            parts[-1],
            src_dir_fd=parent_fd,
            dst_dir_fd=parent_fd,
        )
        temporary_name = None
    finally:
        if temporary_fd is not None:
            os.close(temporary_fd)
        if temporary_name is not None:
            try:
                os.unlink(temporary_name, dir_fd=parent_fd)
            except FileNotFoundError:
                pass
        os.close(parent_fd)


def unzip(
    filename,
    output_dir=None,
    max_extracted_bytes=DEFAULT_MAX_EXTRACTED_BYTES,
    max_archive_members=DEFAULT_MAX_ARCHIVE_MEMBERS,
):
    output_dir = output_dir or os.getcwd()
    logging.info("Extracting file: %s", filename)
    require_secure_extraction_support()
    output_root = os.path.abspath(output_dir)

    with zipfile.ZipFile(filename, "r") as zip_ref:
        members = list(
            safe_zip_members(
                zip_ref,
                output_dir,
                max_extracted_bytes=max_extracted_bytes,
                max_archive_members=max_archive_members,
            )
        )
        root_fd = open_output_root(output_root)
        try:
            for member in members:
                extract_zip_member(zip_ref, member, output_root, root_fd)
        finally:
            os.close(root_fd)


if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    load_and_unzip_data()
