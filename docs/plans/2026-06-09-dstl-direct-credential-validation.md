# DSTL Direct Credential Validation

Status: Completed
Date: 2026-06-09

## Goal

Reject blank or malformed caller-supplied Kaggle credentials before any download
request is posted.

## Changes

- Added `normalize_credentials` so file-loaded and direct credential dictionaries
  share the same non-blank `UserName`/`Password` validation.
- Updated `download_url` to validate supplied credentials before selecting the
  HTTP client and posting a request.
- Added an offline unit test proving blank supplied credentials do not reach the
  fake HTTP session.
- Extended the baseline, README, SECURITY, changelog, and vision with the direct
  credential validation contract.

## Verification

- `sh -n scripts/check-baseline.sh`
- `scripts/check-baseline.sh`
- `python3 -m py_compile utils.py tests/testutils.py`
- `python3 -m unittest discover -s tests -p "test*.py"`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
