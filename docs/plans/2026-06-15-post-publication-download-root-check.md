---
title: Post-Publication Download Root Check
type: reliability
status: planned
date: 2026-06-15
execution: code
---

# Post-Publication Download Root Check

## Problem

`download_url` verifies the output root before publishing a validated partial
file through its held directory descriptor. The output pathname can still be
replaced after that check and before the function returns. In that race, the
download is published in the original held directory while the returned path
identifies a different directory.

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
