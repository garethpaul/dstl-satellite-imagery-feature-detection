# Reject Archive File And Directory Prefix Collisions

status: planned

## Context

Archive preflight rejects duplicate normalized target paths, but distinct paths
can still be structurally incompatible. A file member named `nested` conflicts
with `nested/file.txt`; depending on member order, extraction can write one
member before descriptor-relative directory creation fails.

## Requirements

- R1. Reject an archive when any file target is also required as a directory
  by another member.
- R2. Detection must be independent of archive member order and occur before
  any destination file is written.
- R3. Preserve safe explicit directories, implicit parent directories,
  case-normalized exact-collision checks, symlink guards, resource limits, and
  descriptor-relative extraction.
- R4. Offline tests and static contracts must reject removal or order-sensitive
  weakening of the prefix-collision preflight.

## Scope Boundaries

- Do not change download URLs, credentials, dependencies, workflow metadata,
  archive size/member limits, or destination race handling.
- Do not extract competition data or make a live Kaggle request.
- Do not introduce platform-specific behavior beyond the existing secure
  descriptor-relative extraction requirement.

## Implementation

- Track normalized file targets and paths required to be directories during
  `safe_zip_members` preflight.
- Reject both file-first and descendant-first structural collisions.
- Add offline regressions proving neither order writes any archive member.
- Extend the baseline and project guidance with mutation-sensitive completed
  plan evidence.

## Verification

- Run `make check` on locally available supported Python versions.
- Run the rooted Make gate from an external working directory.
- Run isolated hostile mutations for both collision orders, preflight timing,
  regression coverage, documentation, and completed plan evidence.
- Audit exact paths, dependency manifests, generated artifacts, and
  credential-like additions before committing.
