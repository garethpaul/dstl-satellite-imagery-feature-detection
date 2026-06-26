# Changes

## 2026-06-26 14:30 UTC - P1 - Bind cached validation to returned file identity

### Summary

Closed a cache reuse race where `download_url` could validate one ZIP through a
no-follow descriptor but return the pathname of a different file installed
during validation.

### Work completed

- Captured the validated cache descriptor's device, inode, change time, and size.
- Required the cached pathname to remain the same regular file after output-root
  identity verification and before reuse is logged or returned.
- Preserved raced replacement data instead of deleting a file not owned by the
  downloader invocation.
- Added a focused offline regression plus source, documentation, design, and
  implementation contracts.

### Threads

- Started: None — completed directly because the descriptor-to-path gap and fix
  are narrow.
- Continued: Cached download safety hardening from PR #21.
- Stopped: None.

### Files changed

- `utils.py` — binds validated cached descriptors to returned path fingerprints.
- `tests/testutils.py` — covers replacement after successful ZIP validation.
- `scripts/check-baseline.sh` — preserves the new source, test, plan, and
  documentation contracts.
- `README.md`, `SECURITY.md`, `VISION.md`, and `AGENTS.md` — document the cached
  identity boundary.
- `docs/plans/2026-06-26-dstl-cached-download-identity-design.md` and
  `docs/plans/2026-06-26-dstl-cached-download-identity.md` — record the decision
  and implementation evidence.

### Validation

- Focused cached replacement regression — failed before the production change
  and passed afterward with the unowned replacement preserved.
- Two isolated hostile mutations — rejected guard removal and deriving the
  expected fingerprint from the replaced pathname.
- `make check`, `make lint`, `make test`, `make build`, and `make verify` —
  passed in the pinned isolated Python 3.11 environment.
- Ruff format/check, 56 offline tests, bytecode compilation, and pip-audit —
  passed; no known dependency vulnerabilities were reported.
- Hosted CI and exact-head review — pending.

### Bugs / findings

- P1: cache validation was descriptor-safe, but the returned pathname was not
  required to identify the same file.

### Blockers

- Live Kaggle integration remains intentionally outside the offline default gate.

### Next action

- Complete local verification and hostile mutation testing, then open a pull
  request for hosted checks and exact-head review.

## 2026-06-26 13:51 UTC - P2 - Enforce cached download size limits

### Summary

Closed a resource-limit bypass where a valid cached DSTL ZIP larger than
`max_download_bytes` was reused even though the same payload would be rejected
when downloaded.

### Work completed

- Measured cached archive size through the already opened no-follow descriptor.
- Rejected oversized cached ZIPs before credential loading or network dispatch.
- Preserved the cached file unchanged and accepted the exact configured limit.
- Added focused offline regressions, static contracts, and hostile mutation
  verification.

### Threads

- Started: None — completed directly because the boundary and fix are narrow.
- Continued: None.
- Stopped: None.

### Files changed

- `utils.py` — enforces `max_download_bytes` on cached descriptors.
- `tests/testutils.py` — covers oversized rejection and exact-limit acceptance.
- `scripts/check-baseline.sh` — preserves source, test, plan, and documentation
  contracts.
- `README.md`, `SECURITY.md`, `VISION.md`, and `AGENTS.md` — document the cache
  resource boundary.
- `docs/plans/2026-06-26-dstl-cached-download-size-design.md` and
  `docs/plans/2026-06-26-dstl-cached-download-size.md` — record the decision and
  implementation steps.

### Validation

- Focused oversized and exact-limit cached-size regressions — passed.
- Two isolated hostile mutations — rejected guard removal and an off-by-one
  `>=` boundary.
- `make check`, `make lint`, `make test`, `make build`, and `make verify` —
  passed in the pinned isolated Python 3.11 environment.
- Ruff format/check, 55 offline tests, bytecode compilation, and pip-audit —
  passed; no known dependency vulnerabilities were reported.
- Hosted Check run `28242505722` — passed on Python 3.10, 3.12, and 3.14.
- CodeQL run `28242503647` — passed Actions and Python analysis.
- `git diff --check` — passed.
- Codex review helper — blocked by repeated HTTP 401 authentication failures;
  exact-head manual review found no actionable findings.

### Bugs / findings

- P2: caller-configured download limits applied only to response bytes, allowing
  an oversized local cache entry to bypass the same resource policy.

### Blockers

- None for the patch. Live Kaggle integration remains intentionally out of the
  offline default gate, and local Codex API authentication remains unavailable.

### Next action

- Merge PR #21 after the final documentation-only head passes hosted checks.

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
- Hosted Check run `28212622887` — passed on Python 3.10, 3.12, and 3.14.
- CodeQL run `28212621806` — passed for actions and Python analysis.
- Codex review helper with `codex review --base origin/master` — blocked by
  local OpenAI API authentication (HTTP 401); exact-head manual review found no
  actionable findings.

### Bugs / findings

- P1: a URL such as `https://www.kaggle.com:444/...` passed hostname and HTTPS
  checks, allowing local Kaggle credentials to be posted to an arbitrary port.

### Blockers

- None for the patch. Local Codex API authentication remains unavailable, with
  exact-head manual review used instead.

### Next action

- Merge PR #20 after the final documentation-only head passes hosted checks.

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
