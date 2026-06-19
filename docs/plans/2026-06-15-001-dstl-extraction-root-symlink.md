# Reject Symlinked Extraction Roots

status: completed

## Problem

ZIP member paths and nested destination symlinks are guarded, but `unzip`
canonicalizes `output_dir` with `realpath` before descriptor-relative traversal.
An existing symlink in the extraction-root path is therefore followed to its
external target instead of being rejected by the existing `O_NOFOLLOW`
boundary.

## Requirements

1. Preserve the absolute lexical extraction-root path without following
   symlinks before descriptor traversal.
2. Reject an existing symlink in the extraction-root path before any member is
   written outside the requested destination.
3. Preserve creation of missing roots, safe nested extraction, existing-file
   replacement, member preflight, resource limits, and destination-race guards.
4. Add mutation-sensitive source, regression, documentation, and completed-
   plan contracts.

## Scope Boundaries

- Do not change archive-member normalization, download behavior, credentials,
  dependencies, resource limits, or workflow behavior.
- Do not add a pathname-based extraction fallback or weaken descriptor-relative
  `O_NOFOLLOW` traversal.
- Do not use Kaggle credentials, competition data, or live network requests.
- Do not merge or close stacked pull requests without explicit authorization.

## Implementation

1. Use `abspath` rather than `realpath` for the preflight and extraction root.
2. Add a deterministic ZIP regression whose requested output root is a symlink
   to an outside directory, asserting no outside file is created.
3. Extend the static baseline and repository guidance contracts.
4. Run focused tests, hostile mutations, supported Python package gates from
   the repository and an external working directory, and final audits.

## Verification

- The focused root-symlink regression passed and the full offline suite passed
  all 37 tests, including safe missing-root creation and nested destination-race
  coverage.
- Seven hostile mutations were rejected for restored root canonicalization,
  partial `abspath` coverage, removed or weakened regression setup/assertions,
  documentation drift, and reopened plan status.
- `make check` passed under Python 3.12.8 and an isolated Python 3.14.0
  environment, including Ruff format/check, source compilation, and dependency
  audits with no known vulnerabilities; Python 3.12 also passed from an
  external working directory.
- Verification used no Kaggle credentials, competition data, or live network
  request.
