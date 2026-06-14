# Preflight Existing Archive Target Types

status: completed

## Context

Archive preflight rejects unsafe and mutually incompatible member paths, but an
existing destination with the wrong type is discovered only during extraction.
If that conflict appears after a safe member, extraction can publish the safe
member before failing on the later file-to-directory or directory-to-file
mismatch.

## Requirements

- R1. Reject an existing directory at an archive file target during preflight.
- R2. Reject an existing non-directory where an archive member requires a
  directory during preflight.
- R3. A late type mismatch must not write an earlier archive member.
- R4. Preserve existing regular-file replacement, safe existing directories,
  symlink rejection, resource limits, and descriptor-relative extraction.
- R5. Add mutation-sensitive offline tests and static contracts for both type
  directions.

## Scope Boundaries

- Do not change dependencies, workflows, download behavior, credentials,
  resource limits, or archive member normalization.
- Do not weaken descriptor-relative no-follow extraction or atomic publication.
- Do not use Kaggle credentials, competition data, or live network requests.

## Implementation

- Classify each existing member path by whether it must be a directory.
- Reject mismatched existing types while enumerating all members, before the
  extraction root is opened.
- Add regressions with a safe first member and a conflicting second member for
  both type directions.
- Extend baseline and project guidance contracts for the new preflight boundary.

## Verification

- Run the focused archive tests on the locally available Python runtime.
- Run `make check` from the repository root and an external working directory.
- Run isolated hostile mutations for the implementation, both regression
  directions, documentation, and completed plan evidence.
- Audit the exact diff, generated artifacts, dependency manifests, and
  credential-like additions before committing.

## Work Completed

- Classified each existing member path according to whether the archive needs
  it to remain a directory or replace it with a regular file.
- Rejected existing wrong-type paths while all members are still being
  preflighted, before the extraction root is opened.
- Added both late-conflict regressions and preserved existing regular-file
  replacement, safe directory traversal, and destination-race handling.
- Extended static and project guidance contracts for the new boundary.

## Verification Completed

- Python 3.12 passed all 36 offline tests, Ruff format and lint checks, bytecode
  compilation, and dependency audit with no known vulnerabilities.
- The canonical repository-root and external-working-directory `make check`
  gates passed with Python 3.12.
- Seven isolated hostile mutations were rejected across type classification,
  both mismatch directions, test presence, documentation, and completed plan
  evidence.
- Exact-path diff, dependency-manifest, generated-artifact, whitespace, shell,
  and credential-like addition audits passed.
- Verification used no Kaggle credentials, downloaded no competition data,
  and made no live Kaggle request.
