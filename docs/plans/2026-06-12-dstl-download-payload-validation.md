# DSTL Download Payload Validation

Status: Completed

## Goal

Reject corrupt archives and Kaggle HTML/login responses before they become a
successful download or a permanently reused cache entry.

## Prioritized Engineering Work

1. **Validate downloaded and cached ZIP payloads (this change).** Every file in
   the checked-in DSTL allow-list is a ZIP archive, but the downloader currently
   accepts any HTTP 200 body and reuses any regular cached file. Validate both
   paths with the standard-library ZIP parser, remove failed partial downloads,
   and fail before loading credentials when an invalid cache already exists.
2. **Constrain redirect credential forwarding (follow-up).** The legacy
   password POST relies on `requests` redirect behavior. Replace it with a
   maintained Kaggle API flow or an explicitly validated redirect strategy so
   credentials cannot be replayed to an unexpected host.
3. **Close extraction-time path races (follow-up).** Preflight rejects existing
   symlinks, but destination components can still change between preflight and
   `zipfile.extract`. A future change should extract through directory-relative,
   no-follow file descriptors or a staging directory with an atomic promotion
   boundary.

## Changes

- Add a focused archive validator that reports a stable payload-integrity
  failure for malformed, truncated, or non-ZIP files.
- Reject an invalid existing cache before credentials are loaded or a request is
  posted; leave the cache untouched so operators can inspect or remove it.
- Validate the completed `.part` file before atomic replacement and preserve
  the existing cleanup and response-close guarantees on failure.
- Update fake-download fixtures to produce real in-memory ZIP bytes and add
  regressions for invalid cached and streamed payloads.
- Preserve the contract in the executable baseline, README, security policy,
  vision, and changelog.

## Verification

- `make check` passes with 28 tests, Ruff, bytecode compilation, and no known
  dependency vulnerabilities.
- `git diff --check` passes.
- Removing cached-payload validation fails the invalid-cache regression.
- Removing partial-payload validation fails the invalid-stream regression.

## Work Completed

- Added central-directory validation for non-empty ZIP archives without
  rereading every extracted byte.
- Rejected invalid cached payloads before credential loading while leaving the
  file available for operator inspection.
- Rejected malformed, HTML, and empty streamed payloads before atomic
  promotion, with partial-file cleanup and response closure preserved.
- Added offline valid, invalid-cache, invalid-stream, and empty-stream
  regressions plus executable documentation guards.
