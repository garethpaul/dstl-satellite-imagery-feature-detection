---
title: Download Finalization Rollback
type: reliability
status: completed
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

## Status: Completed

## Work Completed

- Track final-name ownership after successful no-clobber publication.
- Remove the invocation-owned final name before retrying partial cleanup when
  post-publication cleanup fails.
- Add fault-injection coverage proving the final and partial names are absent
  and the response is closed after the failure.
- Add ordering-sensitive source, regression, guidance, and completed-plan
  contracts to the baseline gate.

## Verification Completed

- Python 3.12.8 Ruff formatting/lint, all 42 offline tests, bytecode
  compilation, and dependency audit passed with no known vulnerabilities.
- Repository and external-directory `make check` passed the full gate.
- Six isolated hostile mutations were rejected for publication ownership,
  final-name rollback, rollback ordering, regression removal, guidance drift,
  and incomplete plan evidence.
- No credentialed Kaggle request, dataset download, archive extraction, or
  private dataset access was performed.
