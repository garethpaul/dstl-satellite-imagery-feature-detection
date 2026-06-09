---
title: DSTL Check Wrapper
date: 2026-06-08
status: completed
execution: code
---

## Context

The repository has an offline data-loader baseline, but it lacks a root
`make check` command for consistent automation across repositories.

## Goals

- Add a root Makefile with `lint`, `test`, `verify`, and `check` targets.
- Make `make check` run the source baseline and offline unittest discovery.
- Keep the gate free of Kaggle credentials, live downloads, and extracted data.
- Document and preserve the wrapper through README, CHANGES, and the baseline.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
