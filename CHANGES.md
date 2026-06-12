# Changes

## 2026-06-12

- Reject invalid or empty cached ZIP files before loading credentials or
  posting a request.
- Validate completed partial downloads before atomic promotion, removing HTML,
  corrupt, or empty payloads while preserving response closure.
- Add offline regressions for invalid cached and streamed archive payloads.

## 2026-06-10

- Require cached download destinations to be regular non-symlink files before
  treating them as successful archives.
- Create partial downloads exclusively and fail closed if another filesystem
  entry appears after stale-part cleanup.
- Add offline regressions for cached symlinks and partial-file insertion races.
- Bound download bytes, expanded archive bytes, and archive member counts.
- Preflight every archive member and reject existing destination symlinks before
  extraction starts, preventing partial writes and redirected output.
- Pin runtime and verification dependencies and add Ruff and dependency audit checks.
- Add a least-privilege Python 3.10, 3.12, and 3.14 GitHub Actions verification
  matrix using current Node 24-based actions.
- Expand offline regression coverage for resource-limit failures and cleanup.

## 2026-06-09

- Rejected disabled, non-positive, and non-finite download timeout values before
  posting live Kaggle requests.
- Rejected embedded URL credentials before loading or posting local Kaggle
  credentials.
- Normalized direct Kaggle credential dictionaries and rejected blank supplied
  credentials before posting download requests.
- Rejected zip symlink members before extraction and exposed a Python compile
  `make build` gate.
- Restricted live downloads to the checked-in DSTL archive filename list before
  loading or posting credentials.
- Rejected non-Kaggle download hosts before loading or posting credentials.
- Rejected non-HTTPS download URLs before posting Kaggle credentials.

## 2026-06-08

- Added a root `make check` wrapper for the offline loader baseline.
- Made downloads complete atomically by writing to `.part` files, removing
  interrupted partials, and replacing the final archive only after the stream
  succeeds.
- Added bounded HTTP timeouts, HTTP status checks, injectable sessions, chunked
  response writes, response closing, and explicit credential loading to the
  Kaggle data downloader.
- Replaced the live Kaggle test with offline unit tests covering fake downloads,
  credential errors, safe zip extraction, and path traversal rejection.
- Added a repeatable baseline guard, Python dependency manifest, and docs for
  local credentials and verification.
