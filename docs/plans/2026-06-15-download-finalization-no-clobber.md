---
title: Download Finalization No-Clobber Guard
type: security
status: completed
date: 2026-06-15
execution: code
---

# Download Finalization No-Clobber Guard

## Problem Frame

Downloads are streamed into an exclusively created descriptor-relative partial
file, but final publication uses `os.rename`. A competing process can create the
final filename after the cache check and before publication; POSIX rename then
silently replaces that file. Finalization must fail closed instead of clobbering
a raced destination.

## Prioritized Engineering Work

1. **P0 - Destination integrity:** publish validated downloads atomically only
   when the final name is absent.
2. **P1 - Dataset provenance:** execute the authorized Kaggle verification
   matrix and record checksums and source evidence.
3. **P2 - Multi-process coordination:** add an explicit lock if maintainers need
   concurrent downloaders to share work rather than one failing closed.

This change implements P0 only. P1 remains in `DATASET_VERIFICATION.md`; P2 is
not required for safe no-clobber behavior.

## Scope Boundaries

- Replace overwrite-capable final publication with an atomic descriptor-relative
  operation that fails if the destination exists.
- Preserve the validated partial file, fsync, output-root identity checks,
  response closing, and exception cleanup behavior.
- Preserve existing cached valid ZIP handling and all URL, credential, timeout,
  size, archive, and extraction boundaries.
- Do not access Kaggle or regenerate datasets.

## Requirements

- R1. A destination created after the initial cache check must not be replaced.
- R2. The raced destination bytes must remain unchanged.
- R3. Failed publication must remove the downloader's partial file and close the
  response.
- R4. Successful publication must remain atomic within the verified output
  directory and leave only the final filename.
- R5. Secure-platform capability checks must require the descriptor-relative
  primitive used by publication.
- R6. Static contracts must reject overwrite publication, test removal,
  documentation drift, and incomplete plan evidence.

## Implementation Units

### U1: Publish Without Clobbering

Files:

- `utils.py`
- `tests/testutils.py`

Approach:

- Atomically hard-link the validated partial file to the absent final name
  using source and destination directory descriptors.
- Unlink the partial name only after publication succeeds.
- Add a race regression that creates the final file after the network request
  starts and verifies the existing bytes survive.

### U2: Preserve The Contract

Files:

- `scripts/check-baseline.sh`
- `AGENTS.md`
- `CHANGES.md`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `docs/plans/2026-06-15-download-finalization-no-clobber.md`

Approach:

- Require the no-clobber primitive, race test, synchronized guidance, and
  truthful completed verification evidence.

## Verification

- Focused download tests.
- Full repository and external-directory `make check`.
- Python compilation and shell syntax checks.
- Hostile mutations for overwrite publication, link capability, race test,
  cleanup assertion, documentation, and completion evidence removal.
- Exact diff, generated artifact, conflict marker, and credential audits.

## Risks

- Descriptor-relative hard linking must be supported on the host platform; the
  secure download path already fails closed when required primitives are absent.
- Concurrent downloaders may both transfer data, but only one can publish the
  final name and the loser fails without overwriting it.

## Status: Completed

## Work Completed

- Replaced overwrite-capable download publication with descriptor-relative
  hard-link creation that fails when the final name already exists.
- Removed the partial name only after successful publication and retained
  existing exception cleanup for failed races.
- Added a final-name race regression proving competing bytes survive, the
  downloader's partial is removed, and the response closes.
- Split common, download, and extraction capability checks so downloads require
  descriptor-relative hard links while extraction retains the platform's
  descriptor-relative rename capability proxy, and updated static contracts
  and project guidance.

## Verification Completed

- The test-first focused run failed because `os.rename` replaced the competing
  final file; all 41 focused tests passed after the fix.
- Python 3.12.8 repository and external-directory `make check` passed Ruff
  formatting/lint, all 41 tests, bytecode compilation, and dependency audit.
- Six isolated hostile mutations were rejected for overwrite publication, link
  capability, race-test, cleanup-assertion, documentation, and completion
  evidence removal.
- No credentialed Kaggle request, dataset download, or extraction was executed.
