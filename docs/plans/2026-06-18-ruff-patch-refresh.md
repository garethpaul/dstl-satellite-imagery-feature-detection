---
title: Ruff Patch Refresh
status: completed
date: 2026-06-18
---

# Ruff Patch Refresh

## Problem

The exact PR #16 branch passes its complete offline verification gate, but a
bounded package-index comparison reports Ruff 0.15.16 while
`requirements-dev.txt` remains pinned to 0.15.15. Keeping the verification tool
on the current compatible patch reduces avoidable maintenance drift without
changing runtime dependencies or dataset behavior.

## Requirements

1. Update only the direct Ruff development pin from 0.15.15 to 0.15.16.
2. Preserve the current Requests 2.34.2 and pip-audit 2.10.0 pins.
3. Add a static contract for all three reviewed requirement versions and this
   plan's completed evidence.
4. Validate from isolated environments without contacting Kaggle or requiring
   private dataset credentials.
5. Preserve all existing stacked pull requests and the pre-existing cache state
   in other worktrees.

## Implementation

- Update `requirements-dev.txt` to Ruff 0.15.16.
- Extend `scripts/check-baseline.sh` with exact requirement and completed-plan
  contracts.
- Record the maintenance change in `CHANGES.md` and complete this plan with
  actual validation evidence.

## Verification Plan

- POSIX shell syntax and Python compilation
- Isolated installs of runtime and development requirements
- Ruff format and lint, all 46 offline tests, and pip-audit
- Repository-root and external-directory `make check`
- Isolated mutations for the Ruff pin, Requests/pip-audit preservation, plan
  status, and verification evidence
- Exact diff, Python artifact, whitespace, conflict-marker, binary, mode, and
  credential scans

## Risks

- A tool patch can change lint or formatting behavior; the complete gate must
  pass with the isolated 0.15.16 installation.
- No credentialed Kaggle request, dataset download, extraction, private
  dataset, or notebook execution is in scope.
- This change is stacked on PR #16, which must remain open and merge first.

## Status: Completed

## Work Completed

- Updated the direct Ruff development pin from 0.15.15 to Ruff 0.15.16.
- Preserved Requests 2.34.2 and pip-audit 2.10.0 exactly.
- Added static requirement and completed-plan contracts and synchronized the
  project change history.

## Verification Completed

- Isolated Python 3.12.8 and Python 3.14.0 environments installed the exact
  runtime and development requirements and reported Ruff 0.15.16.
- Both environments passed Ruff formatting and lint, all 46 offline tests,
  Python compilation, and pip-audit with no known vulnerabilities.
- Repository-root `make check` passed through both isolated interpreters, and
  external-directory `make check` passed through Python 3.12.8.
- Five isolated dependency-contract mutations were rejected: the Ruff pin,
  preserved Requests and pip-audit pins, plan status, and verification evidence.
- Transient pip cache deserialization warnings did not change the successful
  audit result.
- Exact diff, generated-artifact, untracked-file, credential-shaped addition,
  conflict-marker, binary, file-mode, and whitespace audits passed before
  commit.
- No credentialed Kaggle request, dataset download, archive extraction,
  private dataset, or notebook execution was performed.
