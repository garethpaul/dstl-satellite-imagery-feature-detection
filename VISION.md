## DSTL Satellite Imagery Feature Detection Vision

This document explains the current state and direction of the project.
Project overview and developer docs: [`README.md`](README.md)

DSTL Satellite Imagery Feature Detection is a small Python utility repository
for the Kaggle DSTL satellite imagery competition.

The repository currently focuses on downloading and unzipping competition data
with local Kaggle credentials, plus a small test helper. Project context lives
in [`README.md`](README.md).

The goal is to keep the data-loading utility reproducible and credential-safe
while leaving room for future imagery feature detection work.

The current focus is:

Priority:

- Preserve the Kaggle file list and unzip workflow
- Keep `kaggle_credentials.ini` local and untracked
- Avoid committing downloaded competition archives or extracted datasets
- Make network, timeout, extraction, and dataset assumptions explicit

Current baseline:

- `download_url` uses explicit `(connect, read)` timeouts, checks HTTP status,
  requires HTTPS Kaggle download URLs, restricts downloads to the configured
  DSTL archive list, and accepts an injectable client for offline tests.
- Default tests use fake HTTP responses and temporary zip files instead of live
  Kaggle credentials or downloads.
- Zip extraction validates member paths and rejects symlink members before
  writing files.

Next priorities:

- Replace password-based login flow with a maintained Kaggle API path
- Add optional integration tests for real Kaggle downloads behind an explicit
  opt-in flag
- Define modeling or feature-detection scope before adding notebooks or scripts

Contribution rules:

- One PR = one focused data-loading, test, or documentation change.
- Run `scripts/check-baseline.sh` before pushing loader changes.
- Do not commit Kaggle credentials, downloaded zips, or extracted imagery.
- Keep generated data outside the repository.
- Document any competition-data source or API change.

## Security And Data

Canonical security policy and reporting:

- [`SECURITY.md`](SECURITY.md)

Kaggle credentials must stay in local configuration and out of git. Downloaded
competition data may be large and license-constrained, so it should not be
committed.

Tests should avoid requiring real credentials unless explicitly marked as
integration checks.

## What We Will Not Merge (For Now)

- Credentials or downloaded Kaggle data
- Large notebooks without documented inputs and outputs
- Live-download tests as the default test path
- Model claims without reproducible training or evaluation notes

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
