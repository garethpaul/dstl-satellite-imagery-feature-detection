# DSTL Download Path Boundary

Status: Completed

## Goal

Prevent local filesystem entries from redirecting or impersonating cached and
in-progress Kaggle downloads.

## Changes

- Reuse an existing destination only when `lstat` identifies a regular,
  non-symlink file; reject directories, symlinks, and other special entries
  before credentials are posted.
- Create `.part` files with exclusive creation and `O_NOFOLLOW` where the
  platform exposes it, closing the race between stale-part cleanup and opening
  the new stream destination.
- Keep failure cleanup and HTTP response closure intact when exclusive creation
  detects a concurrently inserted path.
- Add offline tests that prove cached symlinks are rejected before the request
  and that a partial-file symlink inserted by the fake session is never
  followed or allowed to alter its target.
- Preserve the behavior in the baseline, developer documentation, security
  policy, vision, and changelog.

## Verification

- `make check`
- `git diff --check`
- Mutation checks replace exclusive creation and regular-file validation to
  confirm the new regressions fail for each weakened implementation.
