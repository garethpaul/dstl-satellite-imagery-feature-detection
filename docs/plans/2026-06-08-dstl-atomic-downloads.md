---
title: DSTL Atomic Downloads
date: 2026-06-08
status: completed
execution: code
---

## Context

`download_url` streamed responses directly into the final archive path. If a
network interruption happened after some chunks were written, a truncated file
could remain and a later run would skip it because the final filename existed.

## Goals

- Keep interrupted streams from leaving the final archive path behind.
- Remove stale `.part` files before retrying a download.
- Close HTTP responses even when streaming fails.
- Preserve the offline fake-session test path.

## Implementation

- Added a regression test for an interrupted streamed response.
- Changed `download_url` to write chunks to `filename.part`.
- Replaced the final archive with `os.replace` only after streaming succeeds.
- Removed partial files on stream failure before re-raising the original error.

## Verification

- `python3 -m unittest discover -s tests -p "test*.py"`
- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
