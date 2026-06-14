# AGENTS.md

## Repository purpose

`garethpaul/dstl-satellite-imagery-feature-detection` is a public sample, documentation, or utility project. dstl-satellite-imagery-feature-detection https://www.kaggle.com/c/dstl-satellite-imagery-feature-detection

## Project structure

- `Makefile` - repository verification targets
- `scripts` - baseline checks and helper scripts
- `docs` - plans, notes, and generated README assets
- `tests` - tests and fixtures
- `requirements.txt` - Python runtime dependencies
- `requirements-dev.txt` - pinned verification dependencies

## Development commands

- Supported runtime: Python 3.10 or newer; CI covers Python 3.10, 3.12, and 3.14.
- Install dependencies: `python3 -m pip install -r requirements.txt -r requirements-dev.txt`
- Full baseline: `make check`
- Combined verification: `make verify`
- Lint/static checks: `make lint`
- Tests: `make test`
- Build: `make build`
- If a command above skips because a platform toolchain is missing, verify on a machine with that SDK before claiming platform behavior is tested.

## Coding conventions

- Language mix noted in the README: Python (2).
- Prefer dependency-free tests or stdlib checks when legacy packages are unavailable.

## Testing guidance

- Test-related files detected: `tests/`, `tests/testutils.py`
- Start with the narrowest relevant test or Make target, then run `make check` before handing off if the change is not documentation-only.
- Keep README verification notes in sync when commands, fixtures, or supported toolchains change.

## PR / change guidance

- Keep diffs focused on the requested repository and avoid unrelated modernization or formatting churn.
- Preserve public APIs, sample behavior, file formats, and documented environment variables unless the task explicitly changes them.
- Update tests, README notes, or docs/plans when behavior, security posture, or validation commands change.
- Call out skipped platform validation, legacy toolchain assumptions, and any risky files touched in the final summary.

## Safety and gotchas

- `kaggle_credentials.ini` is required only for live downloads and is ignored by git.
- Downloaded `.zip` archives and extracted imagery should stay outside commits.
- Preserve the configurable download, expanded-size, and archive-member limits
  when changing the downloader or extraction flow.
- HTTPS download URLs are enforced before credentials are posted, and live download URLs must use Kaggle hosts without embedded URL credentials.
- File-loaded and supplied credentials are normalized before any request is posted, and blank credentials are rejected.
- Live download filenames must match the checked-in DSTL archive list.
- Zip extraction rejects path traversal and symlink members before writing files.
- Preserve preflight rejection of existing destination type collisions so a
  late file/directory mismatch cannot leave earlier archive members written.
- Preserve descriptor-rooted archive extraction, no-follow directory traversal,
  synced same-directory staging, and atomic replacement; unsupported platforms
  must fail closed.

## Agent workflow

1. Inspect the README, Makefile, manifests, and the files directly related to the request.
2. Make the smallest source or docs change that satisfies the task; avoid generated, vendored, or local-environment files unless required.
3. Run the narrowest useful validation first, then `make check` or the documented package/platform gate when available.
4. If a required SDK, service credential, or external runtime is unavailable, record the skipped command and why.
5. Summarize changed files, commands run, and remaining risks or follow-up validation.
