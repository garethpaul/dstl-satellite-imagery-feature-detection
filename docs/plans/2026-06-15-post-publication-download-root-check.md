---
title: Post-Publication Download Root Check
type: reliability
status: completed
date: 2026-06-15
execution: code
---

# Post-Publication Download Root Check

## Problem

`download_url` verifies the output root before publishing a validated partial
file through its held directory descriptor, but it performs no
post-publication validation. A replacement that is already present after
publication therefore goes undetected: the download remains in the original
held directory while the returned path identifies a different directory.

## Approach

- Revalidate output-root identity after final publication and partial cleanup,
  while publication ownership is still tracked by the existing rollback path.
- On an identity failure, remove the invocation-owned final name through the
  held descriptor and preserve the replacement directory unchanged.
- Add a focused fault-injection regression plus static contracts for the check,
  rollback behavior, guidance, and completed verification evidence.

## Files

- `utils.py`
- `tests/testutils.py`
- `scripts/check-baseline.sh`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`
- `AGENTS.md`
- `docs/plans/2026-06-15-post-publication-download-root-check.md`

## Verification

- Run the complete repository and external-directory gates.
- Prove the regression fails without the post-publication identity check.
- Reject isolated mutations of the check, rollback assertion, regression,
  guidance, and completed plan evidence.
- Audit the exact diff, generated artifacts, and secret patterns before commit.

## Non-Goals

- Do not add cross-process locking or change the no-clobber publication method.
- Do not change archive extraction, credentials, network, or size-limit logic.
- Do not merge or close stacked pull requests without owner authorization.

## Status: Completed

## Work Completed

- Revalidated the descriptor-held output root after final publication and
  partial cleanup, while the invocation-owned final name remains rollbackable.
- Added a fault-injection regression that replaces the output pathname at the
  post-publication boundary and proves neither directory retains the download.
- Added ordering-sensitive source, regression, guidance, and plan contracts.

## Verification Completed

- Focused regression passed after failing against the prior implementation.
- Six isolated hostile mutations were rejected for the post-publication check,
  check count, rollback regression, rollback assertion, guidance, and completed
  plan evidence.
- Python 3.12.8 repository-root and external-directory `make check` passed 43
  offline tests, Ruff formatting and lint, bytecode compilation, and dependency
  auditing with no known vulnerabilities.
- Exact diff, generated-artifact, and secret-pattern audits passed before the
  implementation commit.
