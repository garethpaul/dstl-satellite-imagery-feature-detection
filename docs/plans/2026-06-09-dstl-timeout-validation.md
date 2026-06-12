# DSTL Timeout Validation

Status: Completed
Date: 2026-06-09

## Goal

Prevent callers from disabling bounded network behavior by passing `None`,
non-positive, boolean, or non-finite timeout values into the DSTL downloader.

## Changes

- Added timeout normalization for positive finite scalar values and `(connect,
  read)` timeout pairs.
- Rejected disabled or invalid timeout values before posting a download request.
- Added offline unit coverage for accepted timeout shapes and invalid timeout
  rejection before the fake session is called.
- Extended the source baseline, README, security notes, changelog, and vision
  with the timeout validation contract.

## Verification

- `python3 -m unittest discover -s tests -p "test*.py"`
- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
