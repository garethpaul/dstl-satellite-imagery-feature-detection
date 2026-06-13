---
title: DSTL Archive Destination Race Boundary
type: security
date: 2026-06-13
status: planned
---

# DSTL Archive Destination Race Boundary

## Summary

Replace pathname-based ZIP extraction with directory-descriptor traversal,
no-follow opens, durable per-file staging, and atomic publication so a
destination path cannot be swapped to a symlink after archive preflight.

## Problem Frame

`safe_zip_members` validates every target and existing path component before
writing, but `unzip` later delegates to `ZipFile.extract` using pathnames. A
local actor able to modify the output directory between those operations can
replace a validated directory with a symlink and redirect extraction outside
the intended root. The repository vision explicitly prioritizes closing this
preflight-to-write race.

## Prioritized Engineering Tasks

1. Traverse and create destination directories relative to open directory file
   descriptors with no-follow semantics.
2. Stage each regular file exclusively in its verified parent, flush and
   `fsync`, then atomically replace the target relative to the same descriptor.
3. Reject unsupported platforms and raced symlink/non-directory components
   before any outside write.
4. Add deterministic race, successful nested extraction, replacement, cleanup,
   and unsupported-capability regressions.
5. Enforce source, tests, documentation, and completed verification through the
   existing full repository gate.

## Requirements

- R1. Extraction must never follow a destination symlink introduced after
  archive preflight.
- R2. Every parent component must be opened relative to a verified directory
  descriptor with `O_DIRECTORY` and `O_NOFOLLOW`.
- R3. File content must be written to an exclusive same-directory temporary,
  flushed, synced, closed, and atomically replaced through directory-relative
  operations.
- R4. Any open, copy, flush, sync, or replace failure must remove the temporary
  file and preserve an existing target when publication has not occurred.
- R5. Existing path traversal, archive symlink, collision, expanded-size, and
  member-count rejection must remain unchanged.
- R6. Successful extraction must retain nested directories and replacement of
  existing regular files without leaving temporary artifacts.
- R7. Platforms lacking the required descriptor-relative/no-follow operations
  must fail closed with a stable error before extraction.
- R8. Offline tests and `make check` must enforce the implementation,
  regressions, documentation, and truthful completed-plan evidence.

## Key Technical Decisions

- **Descriptor-rooted traversal:** Hold the output root and each parent directory
  open while resolving member components, removing pathname re-resolution from
  the write boundary.
- **No-follow directories and files:** Require `O_NOFOLLOW`; treat symlink or
  non-directory races as extraction errors.
- **Atomic per-file publication:** Generate an unpredictable hidden temporary
  basename, create it with `O_EXCL`, copy and sync through the descriptor, then
  use `os.replace` with source and destination directory descriptors.
- **Fail closed on unsupported hosts:** This repository already depends on
  POSIX shell tooling; security must not silently fall back to raced pathname
  extraction.
- **Preserve archive preflight:** Keep `safe_zip_members` as the complete
  archive-level validation pass before descriptor-rooted writes begin.

## Implementation Units

### U1. Add Descriptor-Rooted Extraction Helpers

- **Files:** `utils.py`
- **Goal:** Validate platform capabilities, open/create directories without
  following links, stage/sync/replace member files, and clean failures.
- **Covers:** R1, R2, R3, R4, R6, R7

### U2. Replace Pathname Extraction And Add Regressions

- **Files:** `utils.py`, `tests/testutils.py`
- **Goal:** Route all preflighted members through the secure helper and prove
  race rejection, nested success, regular-file replacement, cleanup, and
  unsupported-platform failure.
- **Covers:** R1, R4, R5, R6, R7

### U3. Enforce And Document The Boundary

- **Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `VISION.md`,
  `CHANGES.md`, `AGENTS.md`
- **Goal:** Keep the no-follow/dirfd source shape, regression names, platform
  limitation, and completed evidence mandatory in `make check`.
- **Covers:** R8

## Verification

- Run focused extraction tests, Ruff format/check, bytecode compilation,
  dependency audit, `make check`, and the rooted external-working-directory
  wrapper on available supported Python versions.
- Apply isolated mutations for restored `ZipFile.extract`, removed
  `O_NOFOLLOW`, pathname replacement, omitted sync/cleanup, removed race and
  preservation tests, documentation drift, and incomplete plan evidence.
- Run shell syntax, whitespace, exact-path, secret-pattern, and artifact checks.
- Do not use Kaggle credentials, download competition data, or make live
  network requests.

## Risks

- Descriptor-relative flags and replacement are POSIX-oriented; unsupported
  platforms will fail closed instead of extracting insecurely.
- Atomic replacement changes the target inode and applies the extractor's file
  mode rather than preserving a previous target's metadata.
- Directory metadata is not synced; the scope is preventing redirected or
  partial file publication, not crash-consistent directory trees.
