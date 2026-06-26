# Cached download identity binding implementation plan

status: completed

1. Add a failing cached-file replacement regression.
2. Bind validated descriptor and returned pathname fingerprints.
3. Add mutation-sensitive project contracts and documentation.
4. Run focused, full, and hosted verification.

## Verification completed

- The cached-file replacement regression failed first because the replaced
  pathname was returned without error.
- The focused regression and all 56 offline tests pass with the unowned
  replacement preserved.
- Two isolated hostile mutations were rejected: removing the final fingerprint
  guard and deriving the expected fingerprint from the replaced pathname.
- `make check`, `make lint`, `make test`, `make build`, and `make verify` passed
  in the pinned isolated Python 3.11 environment with Ruff, bytecode compilation,
  and no known dependency vulnerabilities.
- GitHub Actions Check run `28244664879` passed on Python 3.10, 3.12,
  and 3.14.
- CodeQL run `28244662609` passed Actions and Python analysis.
- The Codex review helper was attempted and blocked by repeated HTTP 401
  authentication failures; immutable exact-head manual review found no
  actionable findings.
