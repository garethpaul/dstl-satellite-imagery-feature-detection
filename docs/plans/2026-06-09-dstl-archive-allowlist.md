---
title: DSTL Archive Allowlist
type: security
status: completed
date: 2026-06-09
---

# DSTL Archive Allowlist

## Summary

Restrict live downloader filenames to the checked-in DSTL competition archive
list before Kaggle credentials are loaded or posted.

## Requirements

- R1. Preserve the existing checked-in `DATA_FILES` archive list.
- R2. Reject unexpected archive filenames before loading credentials.
- R3. Keep the HTTPS and Kaggle host checks in place.
- R4. Add offline unit coverage for an unexpected Kaggle-shaped archive URL.
- R5. Update README, VISION, CHANGES, SECURITY, and the baseline guard.

## Verification

- `python3 -m unittest discover -s tests -p "test*.py"`
- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
