import io
import os
import tempfile
import unittest
import zipfile

import utils


def kaggle_url(filename="sample_submission.csv.zip"):
    return utils.BASE_DOWNLOAD_URL + filename


def zip_payload(content=b"payload"):
    payload = io.BytesIO()
    with zipfile.ZipFile(payload, "w") as zip_ref:
        zip_ref.writestr("payload.txt", content)
    return payload.getvalue()


def empty_zip_payload():
    payload = io.BytesIO()
    with zipfile.ZipFile(payload, "w"):
        pass
    return payload.getvalue()


class FakeResponse:
    def __init__(self, chunks=None, headers=None):
        self.chunks = chunks or [zip_payload()]
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
    def __init__(self, response, on_post=None):
        self.response = response
        self.on_post = on_post
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
        if self.on_post:
            self.on_post()
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
        payload = zip_payload(b"abc123")
        response = FakeResponse([payload[:10], b"", payload[10:]])
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
                self.assertEqual(payload, handle.read())

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
        payload = zip_payload(b"fresh")
        response = FakeResponse([payload])
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
                self.assertEqual(payload, handle.read())
            self.assertFalse(os.path.exists(filepath + ".part"))

    def test_download_rejects_invalid_cached_zip_before_credentials(self):
        response = FakeResponse()
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = os.path.join(tmpdir, "sample_submission.csv.zip")
            with open(filepath, "wb") as handle:
                handle.write(b"not a zip")

            with self.assertRaisesRegex(ValueError, "valid ZIP archive"):
                utils.download_url(
                    kaggle_url(),
                    output_dir=tmpdir,
                    session=session,
                    credentials_file=os.path.join(tmpdir, "missing.ini"),
                )

            with open(filepath, "rb") as handle:
                self.assertEqual(b"not a zip", handle.read())

        self.assertEqual([], session.calls)

    def test_download_reuses_valid_cached_zip_before_credentials(self):
        payload = zip_payload(b"cached")
        response = FakeResponse()
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = os.path.join(tmpdir, "sample_submission.csv.zip")
            with open(filepath, "wb") as handle:
                handle.write(payload)

            with self.assertLogs(level="WARNING") as logs:
                result = utils.download_url(
                    kaggle_url(),
                    output_dir=tmpdir,
                    session=session,
                    credentials_file=os.path.join(tmpdir, "missing.ini"),
                )

            self.assertEqual(filepath, result)
            self.assertIn("exists", logs.output[0])
            with open(filepath, "rb") as handle:
                self.assertEqual(payload, handle.read())

        self.assertEqual([], session.calls)

    def test_download_rejects_invalid_streamed_zip_and_removes_partial_file(self):
        response = FakeResponse([b"<html>login required</html>"])
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = os.path.join(tmpdir, "sample_submission.csv.zip")

            with self.assertRaisesRegex(ValueError, "valid ZIP archive"):
                utils.download_url(
                    kaggle_url(),
                    output_dir=tmpdir,
                    session=session,
                    credentials={"UserName": "user", "Password": "pass"},
                )

            self.assertFalse(os.path.exists(filepath))
            self.assertFalse(os.path.exists(filepath + ".part"))

        self.assertTrue(response.closed)

    def test_download_rejects_empty_streamed_zip(self):
        response = FakeResponse([empty_zip_payload()])
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            with self.assertRaisesRegex(ValueError, "non-empty ZIP archive"):
                utils.download_url(
                    kaggle_url(),
                    output_dir=tmpdir,
                    session=session,
                    credentials={"UserName": "user", "Password": "pass"},
                )

            self.assertFalse(os.path.exists(os.path.join(tmpdir, "sample_submission.csv.zip.part")))

        self.assertTrue(response.closed)

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

    def test_download_rejects_existing_symlink_cache_before_request(self):
        response = FakeResponse()
        session = FakeSession(response)

        with tempfile.TemporaryDirectory() as tmpdir:
            outside_path = os.path.join(tmpdir, "outside.zip")
            with open(outside_path, "wb") as handle:
                handle.write(b"outside")
            filepath = os.path.join(tmpdir, "sample_submission.csv.zip")
            os.symlink(outside_path, filepath)

            with self.assertRaisesRegex(ValueError, "regular non-symlink"):
                utils.download_url(
                    kaggle_url(),
                    output_dir=tmpdir,
                    session=session,
                    credentials={"UserName": "user", "Password": "secret"},
                )

            self.assertEqual([], session.calls)
            self.assertTrue(os.path.islink(filepath))

    def test_download_exclusively_creates_partial_file(self):
        response = FakeResponse()

        with tempfile.TemporaryDirectory() as tmpdir:
            outside_path = os.path.join(tmpdir, "outside.zip")
            with open(outside_path, "wb") as handle:
                handle.write(b"outside")
            partial_path = os.path.join(tmpdir, "sample_submission.csv.zip.part")
            session = FakeSession(
                response,
                on_post=lambda: os.symlink(outside_path, partial_path),
            )

            with self.assertRaises(FileExistsError):
                utils.download_url(
                    kaggle_url(),
                    output_dir=tmpdir,
                    session=session,
                    credentials={"UserName": "user", "Password": "secret"},
                )

            with open(outside_path, "rb") as handle:
                self.assertEqual(b"outside", handle.read())
            self.assertFalse(os.path.lexists(partial_path))
            self.assertTrue(response.closed)

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

    def test_unzip_rejects_existing_symlink_in_destination_path(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_dir = os.path.join(tmpdir, "output")
            outside_dir = os.path.join(tmpdir, "outside")
            os.makedirs(output_dir)
            os.makedirs(outside_dir)
            os.symlink(outside_dir, os.path.join(output_dir, "nested"))

            archive = os.path.join(tmpdir, "symlink-path.zip")
            with zipfile.ZipFile(archive, "w") as zip_ref:
                zip_ref.writestr("nested/file.txt", "bad")

            with self.assertRaisesRegex(ValueError, "existing symlink"):
                utils.unzip(archive, output_dir=output_dir)

            self.assertFalse(os.path.exists(os.path.join(outside_dir, "file.txt")))

    def test_unzip_preflights_all_members_before_writing(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_dir = os.path.join(tmpdir, "output")
            archive = os.path.join(tmpdir, "late-traversal.zip")
            with zipfile.ZipFile(archive, "w") as zip_ref:
                zip_ref.writestr("safe.txt", "safe")
                zip_ref.writestr("../outside.txt", "bad")

            with self.assertRaises(ValueError):
                utils.unzip(archive, output_dir=output_dir)

            self.assertFalse(os.path.exists(os.path.join(output_dir, "safe.txt")))
            self.assertFalse(os.path.exists(os.path.join(tmpdir, "outside.txt")))

    def test_unzip_rejects_colliding_target_paths_before_writing(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_dir = os.path.join(tmpdir, "output")
            archive = os.path.join(tmpdir, "colliding-targets.zip")
            with zipfile.ZipFile(archive, "w") as zip_ref:
                zip_ref.writestr("safe.txt", "first")
                zip_ref.writestr("./safe.txt", "second")

            with self.assertRaisesRegex(ValueError, "colliding target paths"):
                utils.unzip(archive, output_dir=output_dir)

            self.assertFalse(os.path.exists(os.path.join(output_dir, "safe.txt")))

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
