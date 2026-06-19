# Descriptor-Rooted Downloads

Status: Completed

## Problem

ZIP extraction now holds a no-follow descriptor for its lexical output root,
but `download_url()` still validates cached archives, creates and removes the
partial file, and publishes the completed archive through repeated pathname
lookups. A symlinked or replaced output-root component can therefore redirect
download filesystem operations outside the requested destination.

## Priorities

1. P0: bind download cache, staging, cleanup, and publication operations to a
   descriptor-verified output root.
2. P1: execute the exact stack with Kaggle credentials and sanitized dataset
   evidence.
3. P2: validate the private archive inventory and downstream loader behavior.

## Requirements

1. Open or create the lexical output root through no-follow descriptor traversal
   before credentials or network requests.
2. Validate cached files through a no-follow descriptor and reject non-regular
   entries without reopening them by pathname.
3. Create, validate, clean up, and atomically publish the partial archive using
   names relative to the held output-root descriptor.
4. Preserve valid cache reuse, ZIP payload checks, timeout and size limits,
   response closure, and returned absolute paths.
5. Add offline root-symlink and root-replacement regressions plus
   mutation-sensitive source, test, guidance, and completed-plan contracts.

## Scope Boundaries

- Do not change Kaggle endpoints, credentials, archive allowlists, limits, or
  extraction behavior.
- Do not add dependencies or use credentialed/live dataset traffic.
- Fail closed when required POSIX descriptor primitives are unavailable.
- Do not merge or close stacked pull requests without explicit authorization.

## Implementation

1. Generalize the existing descriptor-support and output-root traversal helpers
   so download and extraction can share them.
2. Let ZIP validation consume an already-open binary file object.
3. Refactor `download_url()` to keep an output-root descriptor open for the
   entire cache/download lifecycle and use relative descriptor operations.
4. Add deterministic offline regressions that prove symlinked and replaced
   roots do not receive cache or partial archive writes.
5. Extend the baseline and project guidance, then run focused tests, hostile
   mutations, Python 3.12/3.14 `make check`, an external-directory gate, and
   final artifact, secret, and diff audits.

## Verification

- The test-first run failed only the two new root-symlink and root-replacement
  regressions; a plan-aware review then caught and fixed cached-root identity
  revalidation. All 40 offline tests passed after both changes.
- Seven hostile mutations were rejected for root opening, both identity checks,
  descriptor-relative staging, both focused regressions, README guidance, and
  completed plan evidence.
- One additional review-regression mutation proved cached archive validation
  cannot bypass the held-root identity check.
- Python 3.12.8 and isolated Python 3.14.0 `make check` passed with Ruff,
  compilation, and dependency audits; Python 3.12.8 also passed from an external working directory.
- No Kaggle credentials, live network request, private dataset, extraction
  inventory, or loader scenario was used.
