# Reject Archive File And Directory Prefix Collisions

status: completed

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

## Work Completed

- Tracked normalized file targets separately from paths required to remain
  directories during archive preflight.
- Rejected file-first and descendant-first prefix collisions before opening
  the extraction root or writing a destination member.
- Added offline order regressions while preserving safe nested extraction,
  exact target collision handling, resource limits, and no-follow extraction.
- Added static and documentation contracts for the structural collision
  boundary.

## Verification Completed

- Fresh isolated Python 3.12.8 and Python 3.14.0 environments passed dependency
  integrity, all 35 offline tests, Ruff format/check, bytecode compilation, and
  dependency audits with no known vulnerabilities.
- `make check` passed in both isolated environments, and the rooted external
  working-directory gate passed with Python 3.12.8.
- Eight isolated hostile mutations were rejected across both collision orders,
  preflight state, regression coverage, documentation, and completed plan
  evidence.
- Shell syntax, `git diff --check`, exact-path inspection, unchanged dependency
  manifests, generated-artifact inspection, and credential-like addition
  inspection passed.
- Verification used no Kaggle credentials, downloaded no competition data, and made no live Kaggle request.
