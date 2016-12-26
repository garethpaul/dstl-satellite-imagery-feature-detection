import os

import requests
import shutil
import zipfile
import logging
import configparser



def load_and_unzip_data():
    url = "https://www.kaggle.com/account/login?ReturnUrl=/c/dstl-satellite-imagery-feature-detection/download/"

    files = [
        "sample_submission.csv.zip",
        "grid_sizes.csv.zip",
        "sixteen_band.zip",
        "three_band.zip",
        "train_geojson_v3.zip",
        "train_wkt_v4.csv.zip"
    ]

    logging.info("Start loading files ...\n")
    for filename in files:
        download_url(url + filename)

    logging.info("Extracting files")
    for filename in files:
        if filename.endswith('zip'):
            unzip(filename=filename)


def download_url(url):
    filename = url.split('/')[-1]

    if os.path.exists(os.path.join(os.getcwd(), filename)):
        logging.warning("File %s exists" % filename)
        return

    config = configparser.ConfigParser()
    cwd = os.path.dirname(os.path.realpath(__file__))
    config.read(os.path.join(cwd, 'kaggle_credentials.ini'))
    login = config['KAGGLE']['login']
    password = config['KAGGLE']['password']
    # Kaggle Username and Password
    kaggle_info = {'UserName': login, 'Password': password}


    # Login to Kaggle and retrieve the data.
    r = requests.post(url, data=kaggle_info, stream=True)

    logging.info("Load file %s\n" % filename)
    with open(filename, "wb") as f:
        shutil.copyfileobj(r.raw, f)
    logging.info("FINISH file %s\n" % filename)
    logging.info("File size: %d kb", os.path.getsize(filename=filename))
    return

def unzip(filename):
    logging.info("Extracting file: %s" % filename)
    with zipfile.ZipFile(filename, "r") as zip_ref:
        zip_ref.extractall()

if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    load_and_unzip_data()