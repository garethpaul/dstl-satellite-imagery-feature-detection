# Changes

## 2026-06-09

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
