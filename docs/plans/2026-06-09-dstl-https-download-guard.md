---
title: DSTL HTTPS Download Guard
date: 2026-06-09
status: completed
execution: code
---

## Context

`download_url` posts Kaggle credentials to the supplied download URL. The
default competition URL is HTTPS, but callers could pass a plain-HTTP URL and
send credentials over cleartext.

## Goals

- Reject non-HTTPS download URLs before loading or posting credentials.
- Keep offline tests free of live Kaggle network access.
- Extend the source baseline and documentation for the HTTPS transport guard.

## Verification

- `python3 -m unittest discover -s tests -p "test*.py"`
- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
