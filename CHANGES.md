# Changes

## 2026-06-25 19:10 PDT - P1 - Reject explicit Kaggle download ports

### Summary

Closed a credential authority gap where exact Kaggle hostnames with arbitrary
explicit ports reached credential loading and request dispatch. The downloader
now accepts only the default HTTPS authority used by the checked-in endpoint.

### Work completed

- Added an offline regression that covers explicit ports `443` and `444` and
  asserts no session call occurs.
- Observed the pre-fix test reach missing credential-file loading instead of
  rejecting the URL authority.
- Rejected every parsed explicit port before credentials are loaded or posted.
- Added accepted design and implementation plans plus mutation-sensitive static
  and documentation contracts.

### Threads

- Started: None — completed directly because the boundary and fix are narrow.
- Continued: None.
- Stopped: None.

### Files changed

- `utils.py` — rejects explicit download URL ports.
- `tests/testutils.py` — covers default-looking and arbitrary explicit ports.
- `scripts/check-baseline.sh` — preserves source, test, plan, and documentation
  contracts.
- `README.md`, `SECURITY.md`, `VISION.md`, and `AGENTS.md` — document the
  default HTTPS Kaggle authority boundary.
- `docs/plans/2026-06-25-dstl-kaggle-explicit-port-design.md` and
  `docs/plans/2026-06-25-dstl-kaggle-explicit-port.md` — record the decision and
  implementation steps.

### Validation

- Focused explicit-port regression — passed after the intended pre-fix failure.
- `make check`, `make lint`, `make test`, `make build`, and `make verify` with
  the pinned isolated environment — passed on Python 3.11.
- Ruff format/check, 53 offline tests, bytecode compilation, and pip-audit —
  passed; no known dependency vulnerabilities were reported.
- Three isolated hostile guard mutations — rejected removal, allowing `:443`,
  and rejecting only `:444`.
- `git diff --check` — passed.
- Hosted Python 3.10, 3.12, and 3.14 validation — pending.

### Bugs / findings

- P1: a URL such as `https://www.kaggle.com:444/...` passed hostname and HTTPS
  checks, allowing local Kaggle credentials to be posted to an arbitrary port.

### Blockers

- None.

### Next action

- Commit and open the focused PR, run exact-head review, and merge only after
  the hosted Python matrix passes.

## 2026-06-19

- Preserved primary download errors when response cleanup also fails and made
  rollback unlink only the invocation-owned inode, with final inode verification
  after successful response cleanup.
- Preserved unknown legacy or collided partial files instead of deleting paths
  not created by the current invocation.
- Rejected short response bodies that disagree with `Content-Length`.
- Rejected ZIP special-file members and portable case or Unicode-normalization
  target collisions before extraction.

## 2026-06-18

- Refreshed the pinned Ruff verification tool to 0.15.16 while preserving the
  runtime dependency, audit tool, 46-test suite, and offline dataset boundary.

## 2026-06-15

- Rolled back published downloads when response finalization failed and moved
  the final output-root identity check after response close.
- Isolated concurrent downloads with secret-suffixed partial names on the
  current rollback and post-publication verification stack.
- Revalidated download-root identity after final publication and rolled back
  invocation-owned files when the output pathname changed.
- Rolled back owned final download names when post-publication cleanup fails.
- Prevented download finalization from clobbering raced destination files.
- Bound download cache and publication operations to a descriptor-verified output root.
- Rejected symlinked extraction roots before descriptor traversal and member writes.

## 2026-06-14

- Added an exact-head DSTL dataset integration verification matrix that
  separates offline checks from sanitized credentialed download, extraction,
  private dataset, resource, and loader evidence.
- Reject existing destination type collisions during archive preflight so a
  later file/directory mismatch cannot leave earlier members written.

## 2026-06-13

- Reject archive file and directory prefix collisions in either member order
  before any destination file is written.
- Closed archive destination path races with descriptor-rooted no-follow
  traversal, synced temporary files, atomic replacement, and failure cleanup.
- Reject ZIP members whose normalized destination paths collide, before any
  archive member is written.
- Added offline regression and static contracts for alias-path collisions.

## 2026-06-12

- Reject invalid or empty cached ZIP files before loading credentials or
  posting a request.
- Validate completed partial downloads before atomic promotion, removing HTML,
  corrupt, or empty payloads while preserving response closure.
- Add offline regressions for invalid cached and streamed archive payloads.
- Disable checkout credential persistence, pin the Ubuntu runner, and make the
  complete verification gate independent of the caller's working directory.
- Propagate the selected Python interpreter into the baseline script and run
  unittest discovery from the repository root.
- Reject extra or release-tagged workflow actions outside the two reviewed
  immutable action pins.

## 2026-06-10

- Require cached download destinations to be regular non-symlink files before
  treating them as successful archives.
- Create partial downloads exclusively and fail closed if another filesystem
  entry appears after stale-part cleanup.
- Add offline regressions for cached symlinks and partial-file insertion races.
- Bound download bytes, expanded archive bytes, and archive member counts.
- Preflight every archive member and reject existing destination symlinks before
  extraction starts, preventing partial writes and redirected output.
- Pin runtime and verification dependencies and add Ruff and dependency audit checks.
- Add a least-privilege Python 3.10, 3.12, and 3.14 GitHub Actions verification
  matrix using current Node 24-based actions.
- Expand offline regression coverage for resource-limit failures and cleanup.

## 2026-06-09

- Rejected disabled, non-positive, and non-finite download timeout values before
  posting live Kaggle requests.
- Rejected embedded URL credentials before loading or posting local Kaggle
  credentials.
- Normalized direct Kaggle credential dictionaries and rejected blank supplied
  credentials before posting download requests.
- Rejected zip symlink members before extraction and exposed a Python compile
  `make build` gate.
- Restricted live downloads to the checked-in DSTL archive filename list before
  loading or posting credentials.
- Rejected non-Kaggle download hosts before loading or posting credentials.
- Rejected non-HTTPS download URLs before posting Kaggle credentials.

## 2026-06-08

- Added a root `make check` wrapper for the offline loader baseline.
- Made downloads complete atomically by writing to `.part` files, removing
  interrupted partials, and replacing the final archive only after the stream
  succeeds.
- Added bounded HTTP timeouts, HTTP status checks, injectable sessions, chunked
  response writes, response closing, and explicit credential loading to the
  Kaggle data downloader.
- Replaced the live Kaggle test with offline unit tests covering fake downloads,
  credential errors, safe zip extraction, and path traversal rejection.
- Added a repeatable baseline guard, Python dependency manifest, and docs for
  local credentials and verification.
