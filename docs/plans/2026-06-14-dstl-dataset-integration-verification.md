---
title: DSTL Dataset Integration Verification Matrix
type: reliability
status: in_progress
date: 2026-06-14
---

# DSTL Dataset Integration Verification Matrix

## Status: In Progress

## Problem Frame

Offline checks cover credential validation, HTTPS and Kaggle host restrictions,
bounded downloads, payload validation, safe archive extraction, collision and
race defenses, resource limits, and loader helpers. The repository does not
define repeatable exact-head evidence for a credentialed Kaggle download,
competition archive inventory, extraction, or dataset loader smoke run.

## Scope Boundaries

- Do not change downloader, archive, credential, resource, dependency, dataset,
  or loader behavior.
- Do not add Kaggle credentials, signed URLs, dataset archives, extracted
  imagery, labels, account identifiers, screenshots, paths, or logs.
- Do not claim live Kaggle, archive, imagery, or loader execution from offline
  unit, lint, compile, or dependency checks.
- Do not merge or close stacked pull requests without explicit authorization.

## Requirements

- R1. Add an exact-commit matrix for isolated environment setup, credential
  preflight, cache reuse, bounded download, payload validation, extraction,
  dataset inventory, resource budgets, and loader smoke behavior.
- R2. Require a private competition-authorized environment, sanitized counts
  and size buckets, and explicit `pass`, `fail`, `blocked`, or `not run` status.
- R3. Keep offline checks, synthetic archive tests, credentialed download,
  extracted dataset, and loader evidence separate.
- R4. Add mutation-sensitive contracts for the matrix, project guidance, and
  completed plan evidence.

## Implementation

1. Add the dataset integration matrix with all scenarios marked `not run`.
2. Link the matrix from project guidance and document evidence sanitization.
3. Extend the deterministic checker with scenario, status, and plan contracts.
4. Run focused, full, external-directory, audit, and hostile mutation gates.

## Verification

- `sh -n scripts/check-baseline.sh`
- `make check` from repository and external working directories
- Python 3.12 and 3.14 full gates
- Ruff, unit tests, compilation, and pip-audit
- Isolated hostile documentation mutations
- Exact diff, generated-artifact, and secret-pattern audits
