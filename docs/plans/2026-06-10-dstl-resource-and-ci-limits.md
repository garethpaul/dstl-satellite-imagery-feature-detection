# DSTL Resource Limits and CI Gate

Status: Completed

## Goal

Prevent unbounded network and archive processing while making the repository's
quality gate reproducible on every change.

## Changes

- Cap each download at 25 GiB by default and enforce both declared and streamed
  byte counts while retaining atomic partial-file cleanup.
- Reject archives whose declared expanded size exceeds 100 GiB or whose member
  count exceeds 100,000 before extracting files.
- Preflight every member before extraction begins and reject existing symlinks
  in destination paths so invalid archives cannot leave partial or redirected
  output.
- Allow callers to override each limit with a positive integer for known data
  sets.
- Pin runtime and development dependencies, add Ruff formatting and linting,
  and audit installed dependencies.
- Run the full gate in a least-privilege Python 3.10, 3.12, and 3.14 GitHub
  Actions matrix with immutable current Node 24 action references, manual
  dispatch, stale-run cancellation, a pinned Ubuntu runner, disabled checkout
  credential persistence, and a job timeout.
- Resolve all Makefile paths from the repository so the gate behaves the same
  when invoked through `make -f` from another working directory.
- Restrict the workflow to the two reviewed immutable action references.

## Verification

- Python 3.12.8 and an isolated Python 3.14.0 environment: `make check` passed
  all 28 tests, Ruff formatting and linting, bytecode compilation, and audits
  of both declared requirements files with no known vulnerabilities.
- Resource-limit regression tests cover declared download size, streamed
  download size and cleanup, expanded archive size, and archive member count.
- Archive regressions cover destination symlinks and confirm a late invalid
  member is rejected before any earlier member is written.
- Six isolated hostile mutations were rejected: removing the download cap,
  removing the archive-member cap, removing the HTTP timeout keyword, restoring
  checkout credentials, adding workflow write permission, and marking this plan
  incomplete.
- Pull-request run `27393956956` passed the full gate on Python 3.10, 3.12, and
  3.14 at exact head `d9a787eb09b3368485b4acc434ad77fe7e979a25`.
