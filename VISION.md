## DSTL Satellite Imagery Feature Detection Vision

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
- Make network and dataset assumptions explicit

Next priorities:

- Add README setup for Kaggle credentials and expected local files
- Replace password-based login flow with a maintained Kaggle API path
- Add tests that do not depend on live credentials or large downloads
- Define modeling or feature-detection scope before adding notebooks or scripts

Contribution rules:

- One PR = one focused data-loading, test, or documentation change.
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
