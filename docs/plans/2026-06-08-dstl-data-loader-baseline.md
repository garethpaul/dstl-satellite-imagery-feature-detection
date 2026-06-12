---
title: DSTL data loader reliability baseline
date: 2026-06-08
status: completed
execution: code
---

## Context

The repository contains a small Python helper for downloading Kaggle DSTL competition archives and unzipping them locally. The original test path required live Kaggle credentials and a network download, while the downloader had an outbound request without an explicit timeout and zip extraction did not guard against unsafe archive paths.

## Goals

- Make `download_url` bounded and testable without real Kaggle credentials.
- Keep Kaggle credentials local through `kaggle_credentials.ini` and clear errors.
- Prevent zip path traversal during extraction.
- Replace the default live-download test with offline unit tests.
- Add a repeatable repository check script and document the Python setup path.

## Scope Boundaries

- Keep the legacy username/password Kaggle flow for compatibility in this pass.
- Do not add modeling code, notebooks, or competition data.
- Do not commit credentials, downloaded archives, or extracted imagery.

## Implementation Units

### U1: Downloader guardrails

Files: `utils.py`, `tests/testutils.py`

Approach: Add `DEFAULT_TIMEOUT`, injectable sessions and credentials, explicit
`raise_for_status`, chunked response writes, response closing, output directory
handling, and credential validation.

Verification: Offline tests assert the session receives the timeout,
credentials, stream flag, chunk size, response close, and output path.

### U2: Safe unzip

Files: `utils.py`, `tests/testutils.py`

Approach: Validate every zip member resolves inside the output directory before extraction.

Verification: Unit tests cover safe nested extraction and path traversal rejection.

### U3: Reproducible baseline

Files: `requirements.txt`, `scripts/check-baseline.sh`, `README.md`, `VISION.md`, `docs/bugs/p2-python-http-call-without-timeout-3955c83cfecd63ea.md`

Approach: Document Python 3 and `requests`, add an offline test command, add an AST guard for HTTP calls without timeout, and mark the timeout bug as resolved by the baseline.

Verification: `scripts/check-baseline.sh`, `python3 -m unittest discover -s tests -p 'test*.py'`, and `git diff --check` pass.
