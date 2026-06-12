# DSTL URL Credential Guard

Status: Completed
Date: 2026-06-09

## Goal

Reject credential-bearing download URLs before the DSTL downloader loads or
posts local Kaggle credentials.

## Changes

- Rejected parsed URL usernames or passwords in the download URL guard.
- Added an offline regression test proving embedded URL credentials are rejected
  before any request is posted.
- Extended the source baseline, README, security notes, changelog, and vision
  with the URL credential contract.

## Verification

- `scripts/check-baseline.sh`
- `python3 -m unittest discover -s tests -p "test*.py"`
- `make check`
- `git diff --check`
