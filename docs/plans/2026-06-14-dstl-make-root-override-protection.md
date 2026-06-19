---
title: DSTL Make Repository Root Override Protection
type: reliability
status: completed
date: 2026-06-14
---

# DSTL Make Repository Root Override Protection

## Status: Completed

## Problem Frame

The Makefile derives the checkout path in `ROOT`, but command-line assignments
override that value. `make ROOT=/tmp check` therefore attempts to execute an
untracked `/tmp/scripts/check-baseline.sh` instead of the repository gate.

## Scope Boundaries

- Preserve all lint, test, build, verification, and dependency-audit behavior.
- Preserve `PYTHON` as an intentional caller-selected interpreter override.
- Do not change downloader, archive, credential, resource, or dataset behavior.
- Keep Make commands independent of the caller's working directory.

## Requirements

- R1. Derive the repository root from the loaded Makefile itself.
- R2. Command-line and environment assignments must not redirect that root.
- R3. The deterministic checker must enforce the protected assignment form.
- R4. The full gate must pass from repository and external working directories.
- R5. Isolated mutations that restore caller control must fail verification.

## Implementation

1. Protect the Makefile repository-root assignment from caller overrides.
2. Update the existing root contract and register this plan in the checker.
3. Run focused, full, external-directory, hostile-override, and mutation gates.

## Verification

- `sh -n scripts/check-baseline.sh`
- `make check`
- External-working-directory `make -C <repository> check`
- Hostile command-line and environment `ROOT` assignments
- Python unit tests, Ruff format/check, compilation, and pip-audit
- `git diff --check`
- Isolated hostile assignment mutations

## Work Completed

- Protected the repository-derived Make root with GNU Make's `override`
  directive while preserving `PYTHON` as a caller-selected interpreter.
- Updated the existing Make contract and registered this plan in the
  deterministic checker.
- Preserved every downloader, archive, resource, and dependency behavior.

## Verification Completed

- `sh -n scripts/check-baseline.sh` and `make lint` passed.
- `make check` passed from the repository and an external working directory.
- Full checks passed with command-line and environment `ROOT=/tmp`
  assignments while commands continued to use the checkout.
- All 36 tests, Ruff format/check, source compilation, and pip-audit passed;
  pip-audit reported no known vulnerabilities.
- Three isolated hostile assignment mutations were rejected: a regular
  assignment, a conditional assignment, and a caller-directory assignment.
