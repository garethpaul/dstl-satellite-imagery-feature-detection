import os
import tempfile
import unittest
import zipfile

import utils


class FakeResponse:
    def __init__(self, chunks=None):
        self.chunks = chunks or [b"payload"]
        self.status_checked = False
        self.closed = False
        self.chunk_size = None

    def raise_for_status(self):
        self.status_checked = True

    def iter_content(self, chunk_size):
        self.chunk_size = chunk_size
        return iter(self.chunks)

    def close(self):
        self.closed = True


class FakeSession:
    def __init__(self, response):
        self.response = response
        self.calls = []

    def post(self, url, data=None, stream=False, timeout=None):
        self.calls.append(
            {
                "url": url,
                "data": data,
                "stream": stream,
                "timeout": timeout,
            }
        )
        return self.response


class FailingResponse(FakeResponse):
    def iter_content(self, chunk_size):
        self.chunk_size = chunk_size
        yield b"partial"
        raise RuntimeError("download interrupted")


class DatasetLoadTest(unittest.TestCase):
    def test_filename_from_legacy_kaggle_login_url(self):
        self.assertEqual(
            "sample_submission.csv.zip",
            utils.filename_from_url(utils.BASE_DOWNLOAD_URL + "sample_submission.csv.zip"),
        )

    def test_download_uses_timeout_credentials_and_output_dir(self):
        response = FakeResponse([b"abc", b"", b"123"])
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = utils.download_url(
                "https://example.test/download/sample_submission.csv.zip",
                output_dir=tmpdir,
                timeout=(3, 9),
                session=session,
                credentials={"UserName": "user", "Password": "pass"},
            )

            self.assertEqual(os.path.join(tmpdir, "sample_submission.csv.zip"), filepath)
            with open(filepath, "rb") as handle:
                self.assertEqual(b"abc123", handle.read())

        self.assertTrue(response.status_checked)
        self.assertTrue(response.closed)
        self.assertEqual(utils.CHUNK_SIZE, response.chunk_size)
        self.assertEqual((3, 9), session.calls[0]["timeout"])
        self.assertTrue(session.calls[0]["stream"])
        self.assertEqual({"UserName": "user", "Password": "pass"}, session.calls[0]["data"])

    def test_download_removes_partial_file_on_stream_failure(self):
        response = FailingResponse()
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = os.path.join(tmpdir, "sample_submission.csv.zip")

            with self.assertRaises(RuntimeError):
                utils.download_url(
                    "https://example.test/download/sample_submission.csv.zip",
                    output_dir=tmpdir,
                    session=session,
                    credentials={"UserName": "user", "Password": "pass"},
                )

            self.assertFalse(os.path.exists(filepath))
            self.assertFalse(os.path.exists(filepath + ".part"))

        self.assertTrue(response.status_checked)
        self.assertTrue(response.closed)

    def test_download_removes_stale_partial_file_before_retry(self):
        response = FakeResponse([b"fresh"])
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = os.path.join(tmpdir, "sample_submission.csv.zip")
            with open(filepath + ".part", "wb") as handle:
                handle.write(b"stale")

            utils.download_url(
                "https://example.test/download/sample_submission.csv.zip",
                output_dir=tmpdir,
                session=session,
                credentials={"UserName": "user", "Password": "pass"},
            )

            with open(filepath, "rb") as handle:
                self.assertEqual(b"fresh", handle.read())
            self.assertFalse(os.path.exists(filepath + ".part"))

    def test_missing_credentials_file_has_clear_error(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            missing_path = os.path.join(tmpdir, "missing.ini")

            with self.assertRaises(utils.KaggleCredentialsError):
                utils.load_credentials(missing_path)

    def test_unzip_rejects_path_traversal(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            archive = os.path.join(tmpdir, "bad.zip")
            with zipfile.ZipFile(archive, "w") as zip_ref:
                zip_ref.writestr("../outside.txt", "bad")

            with self.assertRaises(ValueError):
                utils.unzip(archive, output_dir=tmpdir)

            self.assertFalse(os.path.exists(os.path.join(tmpdir, "..", "outside.txt")))

    def test_unzip_extracts_safe_members(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            archive = os.path.join(tmpdir, "safe.zip")
            with zipfile.ZipFile(archive, "w") as zip_ref:
                zip_ref.writestr("nested/file.txt", "ok")

            utils.unzip(archive, output_dir=tmpdir)

            with open(os.path.join(tmpdir, "nested", "file.txt")) as handle:
                self.assertEqual("ok", handle.read())


if __name__ == "__main__":
    unittest.main()
