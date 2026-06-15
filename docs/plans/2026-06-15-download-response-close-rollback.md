---
title: Download Response Close Rollback
status: in_progress
date: 2026-06-15
---

# Download Response Close Rollback

## Problem

`download_url` closes the HTTP response in a `finally` block outside the
invocation-owned publication rollback scope. If `response.close()` raises after
the final hard link is published, the function fails while leaving that final
archive behind. The output-root identity check also runs before close, so a
pathname replacement triggered during response finalization is not detected
before returning the pathname.

## Requirements

1. Keep response cleanup guaranteed for failures before publication.
2. Close a successful response inside the publication transaction.
3. Roll back the invocation-owned final name when response close fails.
4. Revalidate the descriptor-held output root after successful response close.
5. Preserve concurrent no-clobber publication and unique partial-file isolation.

## Implementation

- Track whether response close has been attempted inside the transaction.
- Move the successful close before the final root identity validation.
- Retain fallback close in `finally` only when the transactional close was not
  reached.
- Add fault-injection tests for close failure and close-time output-root
  replacement, plus ordering-sensitive static contracts and guidance.

## Verification Plan

- Focused download close fault-injection tests
- `make check`
- `make -C /tmp -f <worktree>/Makefile check`
- Isolated hostile mutations for close ordering, rollback scope, final identity,
  fault tests, guidance, and plan evidence
- Exact diff, Python artifact, whitespace, conflict-marker, and credential scans

## Status: In Progress

Implementation and verification evidence will be recorded after the gates complete.
