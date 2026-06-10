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
- Allow callers to override each limit with a positive integer for known data
  sets.
- Pin runtime and development dependencies, add Ruff formatting and linting,
  and audit installed dependencies.
- Run the full gate in a least-privilege Python 3.12 GitHub Actions workflow
  with immutable current Node 24 action references and a job timeout.

## Verification

- `make check` (including an audit of both declared requirements files)
- Resource-limit regression tests cover declared download size, streamed
  download size and cleanup, expanded archive size, and archive member count.
- The baseline script protects dependency, workflow, Makefile, and plan
  contracts against accidental removal.
