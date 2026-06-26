# DSTL Kaggle Explicit Port Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Prevent Kaggle credentials from being posted through URLs with explicit ports.

**Architecture:** Extend the existing pre-credential URL authority guard. Keep the hostname and HTTPS checks intact, reject any parsed explicit port, and prove rejection through offline fake-session tests and mutation-sensitive static contracts.

**Tech Stack:** Python 3.10+, `urllib.parse`, `unittest`, Ruff, pip-audit, POSIX shell, GNU Make, GitHub Actions.

---

## Status: Completed

Completed on 2026-06-25. The implementation was reviewed at commit
`e2cbc6abbce2e3f7f5dc6edbec9d791f56f3b1d4`. Hosted Check run `28212622887`
passed on Python 3.10, 3.12, and 3.14, and CodeQL run `28212621806` passed for
actions and Python. The local Codex review helper selected
`codex review --base origin/master` but could not authenticate to the OpenAI API
(HTTP 401); exact-head manual review found no actionable findings.

### Task 1: Prove the boundary gap

- Add a fake-session regression for an explicit Kaggle port.
- Assert rejection occurs before credential-file loading and session use.
- Run the focused test and observe the pre-fix credential error.

### Task 2: Reject explicit ports

- Add the minimal parsed-port guard to `require_https_url()`.
- Cover both explicit `:443` and arbitrary `:444` authorities.
- Run the focused and complete unit test suites.

### Task 3: Preserve the contract

- Require the source guard, tests, plans, and synchronized documentation from
  `scripts/check-baseline.sh`.
- Record the full maintenance cycle in `CHANGES.md`.
- Run hostile mutations that remove or weaken the port guard.

### Task 4: Validate and publish

- Run every Make alias with the pinned dependencies.
- Review the exact branch against `origin/master`.
- Open a focused PR and merge only after hosted checks pass.

## Verification Evidence

- The focused test failed before the source change by reaching missing
  credential-file loading, proving the explicit-port gap.
- `make check`, `make lint`, `make test`, `make build`, and `make verify` passed
  with pinned dependencies in an isolated Python 3.11 environment.
- Ruff formatting and lint, 53 offline unit tests, bytecode compilation, and
  pip-audit passed with no known dependency vulnerabilities.
- Three isolated hostile mutations were rejected: removing the guard, allowing
  explicit `:443`, and rejecting only explicit `:444`.
- Hosted Check passed on all three supported Python versions, and CodeQL passed.
