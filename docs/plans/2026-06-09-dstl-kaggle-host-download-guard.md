---
title: DSTL Kaggle Host Download Guard
date: 2026-06-09
status: completed
execution: code
---

## Context

`download_url` now rejects non-HTTPS URLs before credentials are posted, but an
arbitrary HTTPS host could still receive Kaggle username/password credentials
if a caller supplied an unexpected URL.

## Goals

- Restrict credential-posting downloads to Kaggle hosts.
- Reject non-Kaggle hosts before loading credentials or opening a session.
- Keep the default test path offline by using fake sessions and Kaggle-shaped
  URLs.
- Document the host boundary and preserve it in the source baseline.

## Verification

- `python3 -m unittest discover -s tests -p "test*.py"`
- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
