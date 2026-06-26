# DSTL Kaggle Explicit Port Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Prevent Kaggle credentials from being posted through URLs with explicit ports.

**Architecture:** Extend the existing pre-credential URL authority guard. Keep the hostname and HTTPS checks intact, reject any parsed explicit port, and prove rejection through offline fake-session tests and mutation-sensitive static contracts.

**Tech Stack:** Python 3.10+, `urllib.parse`, `unittest`, Ruff, pip-audit, POSIX shell, GNU Make, GitHub Actions.

---

## Status: In Progress

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
