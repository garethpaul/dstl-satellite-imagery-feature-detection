---
title: Download Finalization Rollback
type: reliability
status: in_progress
date: 2026-06-15
execution: code
---

# Download Finalization Rollback

## Problem Frame

No-clobber publication hard-links a validated private partial file to the final
archive name and then removes the partial name. If that cleanup unlink fails,
the call raises but leaves the final archive published, exposing success state
to other processes while reporting failure to the caller.

## Requirements

- Track whether this invocation published the final hard link.
- If later finalization cleanup fails, remove that owned final name before
  re-raising and still attempt partial-file cleanup.
- Preserve destination no-clobber behavior, response closing, ZIP validation,
  root identity checks, size limits, and successful publication.
- Add a fault-injection regression and fail-closed source/documentation
  contracts for rollback ordering and completed plan evidence.

## Verification Plan

- focused post-link cleanup failure regression
- repository and external-directory `make check`
- hostile mutations for publication ownership, rollback, ordering, regression,
  documentation, and plan status
- exact diff, generated-artifact, conflict-marker, and credential audits

## Scope Boundaries

- Do not access Kaggle or regenerate datasets.
- Do not add multi-process locking or alter extraction behavior.
- Do not merge or close stacked pull requests without owner authorization.

## Work Pending

- Implement owned-publication rollback and regression coverage.
- Update maintained guidance and record the actual verification evidence.
