---
title: DSTL Make Repository Root Override Protection
type: reliability
status: active
date: 2026-06-14
---

# DSTL Make Repository Root Override Protection

## Status: Active

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
