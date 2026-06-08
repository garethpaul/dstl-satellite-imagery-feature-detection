# Changes

## 2026-06-08

- Added bounded HTTP timeouts, HTTP status checks, injectable sessions, and
  explicit credential loading to the Kaggle data downloader.
- Replaced the live Kaggle test with offline unit tests covering fake downloads,
  credential errors, safe zip extraction, and path traversal rejection.
- Added a repeatable baseline guard, Python dependency manifest, and docs for
  local credentials and verification.
