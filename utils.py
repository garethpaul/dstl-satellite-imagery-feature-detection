import configparser
import logging
import math
import os
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

    output_dir = output_dir or os.getcwd()
    os.makedirs(output_dir, exist_ok=True)

    filename = filename_from_url(url)
    require_allowed_data_file(filename)
    filepath = os.path.join(output_dir, filename)
    partial_path = filepath + ".part"

    if os.path.lexists(filepath):
        existing_mode = os.lstat(filepath).st_mode
        if stat.S_ISLNK(existing_mode) or not stat.S_ISREG(existing_mode):
            raise ValueError("Existing download path must be a regular non-symlink file.")
        logging.warning("File %s exists", filepath)
        return filepath

    if os.path.lexists(partial_path):
        os.remove(partial_path)

    credentials = (
        normalize_credentials(credentials)
        if credentials is not None
        else load_credentials(credentials_file)
    )
    client = session or requests

    response = client.post(url, data=credentials, stream=True, timeout=timeout)
    try:
        response.raise_for_status()

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
        open_flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
        if hasattr(os, "O_NOFOLLOW"):
            open_flags |= os.O_NOFOLLOW
        partial_fd = os.open(partial_path, open_flags, 0o600)
        with os.fdopen(partial_fd, "wb") as handle:
            for chunk in response.iter_content(chunk_size=CHUNK_SIZE):
                if chunk:
                    downloaded_bytes += len(chunk)
                    if downloaded_bytes > max_download_bytes:
                        raise ValueError("Download exceeds the configured size limit.")
                    handle.write(chunk)
        os.replace(partial_path, filepath)
    except Exception:
        if os.path.lexists(partial_path):
            os.remove(partial_path)
        raise
    finally:
        close = getattr(response, "close", None)
        if close:
            close()

    logging.info("FINISH file %s", filename)
    logging.info("File size: %d kb", os.path.getsize(filepath))
    return filepath


def safe_zip_members(
    zip_ref,
    output_dir,
    max_extracted_bytes=DEFAULT_MAX_EXTRACTED_BYTES,
    max_archive_members=DEFAULT_MAX_ARCHIVE_MEMBERS,
):
    output_root = os.path.realpath(output_dir)
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

    for member in members:
        if stat.S_ISLNK(member.external_attr >> 16):
            raise ValueError("Refusing to extract zip symlink member.")
        target_path = os.path.abspath(os.path.join(output_root, member.filename))
        if os.path.commonpath((output_root, target_path)) != output_root:
            raise ValueError("Refusing to extract zip member outside output directory.")

        current_path = output_root
        for part in os.path.relpath(target_path, output_root).split(os.sep):
            current_path = os.path.join(current_path, part)
            if os.path.islink(current_path):
                raise ValueError("Refusing to extract through an existing symlink.")
        yield member


def unzip(
    filename,
    output_dir=None,
    max_extracted_bytes=DEFAULT_MAX_EXTRACTED_BYTES,
    max_archive_members=DEFAULT_MAX_ARCHIVE_MEMBERS,
):
    output_dir = output_dir or os.getcwd()
    logging.info("Extracting file: %s", filename)

    with zipfile.ZipFile(filename, "r") as zip_ref:
        members = list(
            safe_zip_members(
                zip_ref,
                output_dir,
                max_extracted_bytes=max_extracted_bytes,
                max_archive_members=max_archive_members,
            )
        )
        for member in members:
            zip_ref.extract(member, output_dir)


if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    load_and_unzip_data()
