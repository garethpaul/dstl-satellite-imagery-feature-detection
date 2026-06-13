---
title: DSTL Archive Target Collisions
type: data-integrity
status: completed
date: 2026-06-13
---

# DSTL Archive Target Collisions

## Summary

Reject archives containing members that normalize to the same destination path
so extraction cannot silently overwrite an earlier member.

## Requirements

- R1. Every member destination must be normalized relative to the resolved
  output directory during preflight.
- R2. A repeated normalized destination must reject the whole archive before
  any member is written.
- R3. Comparison must use the platform path case-normalization rule.
- R4. Existing traversal, symlink, resource, and safe extraction behavior must
  remain unchanged.
- R5. Offline tests, the static baseline, and project guidance must preserve
  the boundary.

## Non-Goals

- Extracting or inspecting live Kaggle archives.
- Changing download, credential, timeout, or resource-limit behavior.
- Overwriting or deleting pre-existing destination files.

## Work Completed

- Added normalized destination uniqueness to archive preflight.
- Added an offline alias-path regression and static contracts.
- Updated project security, vision, change, and maintenance guidance.

## Verification

- Python 3.12.8 with `PYTHONPATH` cleared: all 29 unit tests passed.
- `make PYTHON=python3 check` passed the baseline, Ruff format/check, all 29
  tests, bytecode compilation, and dependency audit with no known
  vulnerabilities.
- Removing collision rejection failed the executable regression.
- Removing platform case normalization failed the static baseline.
- `make check` passed after the completed plan contract was added.
- `git diff --check` passed.
