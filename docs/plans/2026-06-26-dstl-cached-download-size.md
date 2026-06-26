# Cached download size boundary implementation plan

status: completed

1. Add failing oversized cached-ZIP regression.
2. Enforce the limit through the opened descriptor.
3. Add hostile mutation and documentation contracts.
4. Run focused, full, and hosted verification.

## Verification completed

- The oversized cached-ZIP regression failed first because the valid cache was
  reused without raising `ValueError`.
- Oversized rejection and exact-limit acceptance now pass without credential
  loading or session calls.
- Two isolated hostile mutations were rejected: removing the cached-size guard
  and changing `>` to `>=`.
- `make check`, `make lint`, `make test`, `make build`, and `make verify` passed
  in the pinned isolated Python 3.11 environment with 55 offline tests, Ruff,
  bytecode compilation, and no known dependency vulnerabilities.
- GitHub Actions run `28242505722` passed on Python 3.10, 3.12, and 3.14.
- CodeQL run `28242503647` passed Actions and Python analysis.
- `codex review --base origin/master` was attempted and skipped after repeated
  HTTP 401 authentication failures, as permitted by the maintenance loop.
