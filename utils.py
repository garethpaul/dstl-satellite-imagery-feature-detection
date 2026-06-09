import configparser
import logging
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
        login = config["KAGGLE"]["login"].strip()
        password = config["KAGGLE"]["password"].strip()
    except KeyError as exc:
        raise KaggleCredentialsError(
            "kaggle_credentials.ini must define [KAGGLE] login and password."
        ) from exc

    if not login or not password:
        raise KaggleCredentialsError("Kaggle login and password must not be empty.")

    return {"UserName": login, "Password": password}


def load_and_unzip_data(output_dir=None, credentials_file=None, timeout=DEFAULT_TIMEOUT):
    output_dir = output_dir or os.getcwd()
    credentials = load_credentials(credentials_file)

    logging.info("Start loading files ...")
    for filename in DATA_FILES:
        download_url(
            BASE_DOWNLOAD_URL + filename,
            output_dir=output_dir,
            credentials=credentials,
            timeout=timeout,
        )

    logging.info("Extracting files")
    for filename in DATA_FILES:
        if filename.endswith(".zip"):
            unzip(os.path.join(output_dir, filename), output_dir=output_dir)


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
):
    require_https_url(url)

    output_dir = output_dir or os.getcwd()
    os.makedirs(output_dir, exist_ok=True)

    filename = filename_from_url(url)
    require_allowed_data_file(filename)
    filepath = os.path.join(output_dir, filename)
    partial_path = filepath + ".part"

    if os.path.exists(filepath):
        logging.warning("File %s exists", filepath)
        return filepath

    if os.path.exists(partial_path):
        os.remove(partial_path)

    credentials = credentials or load_credentials(credentials_file)
    client = session or requests

    response = client.post(url, data=credentials, stream=True, timeout=timeout)
    try:
        response.raise_for_status()

        logging.info("Load file %s", filename)
        with open(partial_path, "wb") as handle:
            for chunk in response.iter_content(chunk_size=CHUNK_SIZE):
                if chunk:
                    handle.write(chunk)
        os.replace(partial_path, filepath)
    except Exception:
        if os.path.exists(partial_path):
            os.remove(partial_path)
        raise
    finally:
        close = getattr(response, "close", None)
        if close:
            close()

    logging.info("FINISH file %s", filename)
    logging.info("File size: %d kb", os.path.getsize(filepath))
    return filepath


def safe_zip_members(zip_ref, output_dir):
    output_root = os.path.abspath(output_dir)

    for member in zip_ref.infolist():
        if stat.S_ISLNK(member.external_attr >> 16):
            raise ValueError("Refusing to extract zip symlink member.")
        target_path = os.path.abspath(os.path.join(output_root, member.filename))
        if target_path != output_root and not target_path.startswith(output_root + os.sep):
            raise ValueError("Refusing to extract zip member outside output directory.")
        yield member


def unzip(filename, output_dir=None):
    output_dir = output_dir or os.getcwd()
    logging.info("Extracting file: %s", filename)

    with zipfile.ZipFile(filename, "r") as zip_ref:
        for member in safe_zip_members(zip_ref, output_dir):
            zip_ref.extract(member, output_dir)


if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    load_and_unzip_data()
