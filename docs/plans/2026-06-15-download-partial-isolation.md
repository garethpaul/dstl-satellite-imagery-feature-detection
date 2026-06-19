---
title: Concurrent Download Partial Isolation
type: security
status: completed
date: 2026-06-15
execution: code
---

# Concurrent Download Partial Isolation

## Problem Frame

Every download attempt currently writes through the shared
`<filename>.part` name. A concurrent request can unlink another request's
in-flight partial and then replace that name before final publication, causing
the first request to publish or remove the wrong partial file. Each attempt
must own a distinct descriptor-relative temporary name.

## Prioritized Engineering Work

1. **P0 - Partial ownership:** isolate each download attempt from concurrent
   writers in the same verified output directory.
2. **P1 - Shared work:** add an explicit lock only if maintainers want
   concurrent callers to reuse one transfer instead of racing to publish.
3. **P2 - Dataset evidence:** execute the authorized Kaggle verification
   matrix in a private environment.

This change implements P0 only. Existing no-clobber publication means one
concurrent caller may still fail after another caller publishes first.

## Scope Boundaries

- Generate a secret-suffixed partial name for each download attempt.
- Keep exclusive descriptor-relative creation, fsync, ZIP validation,
  output-root identity checks, no-clobber publication, response closing, and
  exception cleanup.
- Preserve cleanup of the legacy deterministic `.part` name for compatibility.
- Do not add cross-process locks, access Kaggle, or regenerate datasets.

## Requirements

- R1. Concurrent attempts for the same final filename must use distinct partial
  names.
- R2. One attempt must not unlink, publish, or clean up another attempt's
  partial file.
- R3. A losing attempt must remove only its own partial and preserve the
  winning final file.
- R4. Successful publication must remain atomic and no-clobbering within the
  verified output directory.
- R5. Static contracts must reject deterministic active partial names, missing
  concurrency coverage, guidance drift, and incomplete plan evidence.

## Implementation Units

### U1: Per-Attempt Partial Names

Files:

- `utils.py`
- `tests/testutils.py`

Use the existing `secrets` dependency to create an attempt-specific partial
name. Add a deterministic regression that starts a nested download while the
first request is active and proves the winner is valid, the loser fails closed,
both responses close, and no partial files remain.

### U2: Preserve The Contract

Files:

- `scripts/check-baseline.sh`
- `AGENTS.md`
- `CHANGES.md`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- this plan

Require the per-attempt name, concurrency regression, synchronized guidance,
and truthful completed verification evidence.

## Verification

- Test-first focused concurrency regression.
- Full repository and external-directory `make check`.
- Python compilation and shell syntax checks.
- Hostile mutations for deterministic active names, token removal, concurrency
  test removal, cleanup weakening, documentation drift, and completion evidence.
- Exact diff, generated artifact, conflict marker, and credential audits.

## Risks

- Concurrent callers can still duplicate network work; the existing
  no-clobber final publication safely permits only one winner.
- Secret-suffixed partial files must be removed on every success and failure
  path to avoid consuming disk space.

## Status: Completed

## Completion Evidence

- Replaced the active shared `.part` name with a per-attempt secret-suffixed
  descriptor-relative name while preserving cleanup of the legacy deterministic
  path.
- Integrated the isolation boundary on top of the final-name rollback and
  post-publication output-root checks without changing their ordering.
- Added a synchronized two-thread regression proving the first request
  publishes its own bytes, the second fails with `FileExistsError`, both
  responses close, and no partial files remain.
- All 44 tests passed with Ruff format/lint on Python 3.12.8.
- Six isolated hostile mutations were rejected for deterministic naming, token
  removal, concurrency-test removal, cleanup weakening, guidance drift, and
  incomplete plan evidence.
- The completed baseline checker passed from an external working directory.
- Repository and external-working-directory `make check` passed compilation,
  tests, Ruff, source contracts, and dependency auditing with no known
  vulnerabilities.
- Exact diff, generated-artifact, conflict-marker, whitespace, and credential
  audits passed before commit.
- No Kaggle credentials, live request, downloaded archive, extraction
  inventory, or private dataset was used.
