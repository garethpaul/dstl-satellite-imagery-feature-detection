---
title: DSTL Zip Symlink Guard
type: security
status: completed
date: 2026-06-09
---

# DSTL Zip Symlink Guard

## Summary

Reject symlink members inside downloaded DSTL zip archives before extraction.

## Requirements

- R1. Keep the existing path traversal guard for archive members.
- R2. Reject zip members whose external attributes mark them as symlinks.
- R3. Keep offline unit coverage for a symlink archive member.
- R4. Update README, VISION, CHANGES, SECURITY, and the baseline guard.
- R5. Expose a Python compile `make build` target and include it in
  verification.

## Verification

- `python3 -m unittest discover -s tests -p "test*.py"`
- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
