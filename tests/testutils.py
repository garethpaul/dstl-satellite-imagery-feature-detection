import os
import tempfile
import unittest
import zipfile

import utils


def kaggle_url(filename="sample_submission.csv.zip"):
    return utils.BASE_DOWNLOAD_URL + filename


class FakeResponse:
    def __init__(self, chunks=None, headers=None):
        self.chunks = chunks or [b"payload"]
        self.headers = headers or {}
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
                kaggle_url(),
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

    def test_normalize_timeout_accepts_positive_scalar_and_pair(self):
        self.assertEqual(5, utils.normalize_timeout(5))
        self.assertEqual(0.5, utils.normalize_timeout(0.5))
        self.assertEqual((3, 9), utils.normalize_timeout((3, 9)))

    def test_normalize_timeout_rejects_disabled_or_invalid_timeouts(self):
        for timeout in (None, 0, -1, True, float("inf"), (3, 0), (3,), [3, 9]):
            with self.subTest(timeout=timeout):
                with self.assertRaises(ValueError):
                    utils.normalize_timeout(timeout)

    def test_download_rejects_invalid_timeout_before_request(self):
        response = FakeResponse()
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            with self.assertRaises(ValueError):
                utils.download_url(
                    kaggle_url(),
                    output_dir=tmpdir,
                    timeout=None,
                    session=session,
                    credentials={"UserName": "user", "Password": "pass"},
                )

        self.assertEqual([], session.calls)

    def test_download_rejects_non_https_url_before_credentials(self):
        response = FakeResponse()
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            with self.assertRaises(ValueError):
                utils.download_url(
                    kaggle_url().replace("https://", "http://", 1),
                    output_dir=tmpdir,
                    session=session,
                    credentials={"UserName": "user", "Password": "pass"},
                )

        self.assertEqual([], session.calls)

    def test_download_rejects_non_kaggle_host_before_credentials(self):
        response = FakeResponse()
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            with self.assertRaises(ValueError):
                utils.download_url(
                    "https://example.test/download/sample_submission.csv.zip",
                    output_dir=tmpdir,
                    session=session,
                    credentials_file=os.path.join(tmpdir, "missing.ini"),
                )

        self.assertEqual([], session.calls)

    def test_download_rejects_embedded_url_credentials_before_credentials(self):
        response = FakeResponse()
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            with self.assertRaises(ValueError):
                utils.download_url(
                    kaggle_url().replace("https://", "https://user:password@", 1),
                    output_dir=tmpdir,
                    session=session,
                    credentials_file=os.path.join(tmpdir, "missing.ini"),
                )

        self.assertEqual([], session.calls)

    def test_download_rejects_unexpected_kaggle_file_before_credentials(self):
        response = FakeResponse()
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            with self.assertRaises(ValueError):
                utils.download_url(
                    kaggle_url("unexpected.zip"),
                    output_dir=tmpdir,
                    session=session,
                    credentials_file=os.path.join(tmpdir, "missing.ini"),
                )

        self.assertEqual([], session.calls)

    def test_download_removes_partial_file_on_stream_failure(self):
        response = FailingResponse()
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = os.path.join(tmpdir, "sample_submission.csv.zip")

            with self.assertRaises(RuntimeError):
                utils.download_url(
                    kaggle_url(),
                    output_dir=tmpdir,
                    session=session,
                    credentials={"UserName": "user", "Password": "pass"},
                )

            self.assertFalse(os.path.exists(filepath))
            self.assertFalse(os.path.exists(filepath + ".part"))

    def test_download_rejects_declared_size_over_limit(self):
        response = FakeResponse(headers={"Content-Length": "11"})
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            with self.assertRaisesRegex(ValueError, "size limit"):
                utils.download_url(
                    kaggle_url(),
                    output_dir=tmpdir,
                    session=session,
                    credentials={"UserName": "user", "Password": "pass"},
                    max_download_bytes=10,
                )

            self.assertFalse(os.path.exists(os.path.join(tmpdir, "sample_submission.csv.zip.part")))
            self.assertTrue(response.closed)

    def test_download_rejects_stream_over_limit_and_removes_partial_file(self):
        response = FakeResponse([b"12345", b"67890", b"x"])
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            with self.assertRaisesRegex(ValueError, "size limit"):
                utils.download_url(
                    kaggle_url(),
                    output_dir=tmpdir,
                    session=session,
                    credentials={"UserName": "user", "Password": "pass"},
                    max_download_bytes=10,
                )

            self.assertFalse(os.path.exists(os.path.join(tmpdir, "sample_submission.csv.zip.part")))
            self.assertTrue(response.closed)

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
                kaggle_url(),
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

    def test_download_rejects_blank_supplied_credentials_before_request(self):
        response = FakeResponse()
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            with self.assertRaises(utils.KaggleCredentialsError):
                utils.download_url(
                    kaggle_url(),
                    output_dir=tmpdir,
                    session=session,
                    credentials={"UserName": "  ", "Password": ""},
                )

        self.assertEqual([], session.calls)

    def test_unzip_rejects_path_traversal(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            archive = os.path.join(tmpdir, "bad.zip")
            with zipfile.ZipFile(archive, "w") as zip_ref:
                zip_ref.writestr("../outside.txt", "bad")

            with self.assertRaises(ValueError):
                utils.unzip(archive, output_dir=tmpdir)

            self.assertFalse(os.path.exists(os.path.join(tmpdir, "..", "outside.txt")))

    def test_unzip_rejects_symlink_members(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            archive = os.path.join(tmpdir, "symlink.zip")
            link_info = zipfile.ZipInfo("link")
            link_info.create_system = 3
            link_info.external_attr = 0o120777 << 16
            with zipfile.ZipFile(archive, "w") as zip_ref:
                zip_ref.writestr(link_info, "../outside.txt")

            with self.assertRaises(ValueError):
                utils.unzip(archive, output_dir=tmpdir)

            self.assertFalse(os.path.lexists(os.path.join(tmpdir, "link")))

    def test_unzip_extracts_safe_members(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            archive = os.path.join(tmpdir, "safe.zip")
            with zipfile.ZipFile(archive, "w") as zip_ref:
                zip_ref.writestr("nested/file.txt", "ok")

            utils.unzip(archive, output_dir=tmpdir)

            with open(os.path.join(tmpdir, "nested", "file.txt")) as handle:
                self.assertEqual("ok", handle.read())

    def test_unzip_rejects_extracted_size_over_limit(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            archive = os.path.join(tmpdir, "large.zip")
            with zipfile.ZipFile(archive, "w") as zip_ref:
                zip_ref.writestr("large.txt", "123456")

            with self.assertRaisesRegex(ValueError, "extracted size limit"):
                utils.unzip(archive, output_dir=tmpdir, max_extracted_bytes=5)

            self.assertFalse(os.path.exists(os.path.join(tmpdir, "large.txt")))

    def test_unzip_rejects_archive_member_count_over_limit(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            archive = os.path.join(tmpdir, "many.zip")
            with zipfile.ZipFile(archive, "w") as zip_ref:
                zip_ref.writestr("first.txt", "1")
                zip_ref.writestr("second.txt", "2")

            with self.assertRaisesRegex(ValueError, "member limit"):
                utils.unzip(archive, output_dir=tmpdir, max_archive_members=1)

            self.assertFalse(os.path.exists(os.path.join(tmpdir, "first.txt")))


if __name__ == "__main__":
    unittest.main()
