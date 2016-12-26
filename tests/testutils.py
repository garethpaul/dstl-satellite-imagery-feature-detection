import os
import unittest
import utils


class DatasetLoadTest(unittest.TestCase):

    def test(self):
        url = "https://www.kaggle.com/account/login?ReturnUrl=/c/dstl-satellite-imagery-feature-detection/download/"
        filename = "sample_submission.csv.zip"
        expected_size = 15246 # 15246 kb
        filepath = os.path.join(os.getcwd(), filename)

        if os.path.exists(filepath):
            os.remove(filepath)

        utils.download_url(url + filename)
        self.assertTrue(os.path.exists(filepath))
        self.assertEqual(expected_size, os.path.getsize(filepath))

