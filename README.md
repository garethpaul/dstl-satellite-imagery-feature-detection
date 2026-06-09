# dstl-satellite-imagery-feature-detection

<!-- README-OVERVIEW-IMAGE -->
![Project overview](docs/readme-overview.svg)

## Overview

`garethpaul/dstl-satellite-imagery-feature-detection` is a public sample, documentation, or utility project. dstl-satellite-imagery-feature-detection https://www.kaggle.com/c/dstl-satellite-imagery-feature-detection

This README is based on the checked-in source, manifests, scripts, and repository metadata on the `master` branch. The project language mix found during review was: Python (2).

## Repository Contents

- `README.md` - project overview and local usage notes
- `docs` - source or example code
- `Makefile` - repository-level verification wrapper
- `SECURITY.md` - security reporting and disclosure guidance
- `tests` - source or example code
- `VISION.md` - project direction and maintenance guardrails

Additional scan context:

- Source directories: docs, tests
- Dependency and build manifests: none detected
- Entry points or build surfaces: Makefile, `scripts/check-baseline.sh`
- Test-looking files: tests/testutils.py

## Getting Started

### Prerequisites

- Git
- Python 3
- `requests` from `requirements.txt`

### Setup

```bash
git clone https://github.com/garethpaul/dstl-satellite-imagery-feature-detection.git
cd dstl-satellite-imagery-feature-detection
python3 -m pip install -r requirements.txt
```

The setup commands above are derived from repository files. Legacy mobile, Python, or JavaScript samples may require older SDKs or package versions than a modern workstation uses by default.

## Running or Using the Project

- `utils.py` downloads the configured Kaggle DSTL archives and extracts them
  into the current working directory by default.
- Downloader helpers require HTTPS download URLs on Kaggle hosts before Kaggle
  credentials are loaded or posted, and reject embedded URL credentials.
- Downloader helpers only accept filenames from the checked-in DSTL archive
  list before Kaggle credentials are loaded or posted.
- Create a local, untracked `kaggle_credentials.ini` beside `utils.py` before
  running live downloads:

```ini
[KAGGLE]
login = your-kaggle-username
password = your-kaggle-password
```

```bash
python3 utils.py
```

## Testing and Verification

Run the offline verification gate:

```bash
make check
python3 -m unittest discover -s tests -p "test*.py"
scripts/check-baseline.sh
make build
python3 -m py_compile utils.py tests/testutils.py
```

`make check` runs the source baseline and offline unittest discovery. Default
tests use fake HTTP responses and temporary files. They do not require Kaggle
credentials, live network access, downloaded archives, or extracted imagery.
The baseline also compiles the Python loader and tests through `make build`.

When the required SDK or runtime is unavailable, use static checks and source review first, then verify on a machine that has the matching platform toolchain.

## Configuration and Secrets

- `kaggle_credentials.ini` is required only for live downloads and is ignored by
  git.
- Downloaded `.zip` archives and extracted imagery should stay outside commits.
- HTTPS download URLs are enforced before credentials are posted, and live
  download URLs must use Kaggle hosts without embedded URL credentials.
- File-loaded and supplied credentials are normalized before any request is
  posted, and blank credentials are rejected.
- Live download filenames must match the checked-in DSTL archive list.
- Zip extraction rejects path traversal and symlink members before writing
  files.

## Security and Privacy Notes

- Review changes touching authentication or token handling; examples from the scan include tests/testutils.py, utils.py.
- Review changes touching network requests, sockets, or service endpoints; examples from the scan include docs/bugs/p2-python-http-call-without-timeout-3955c83cfecd63ea.md, tests/testutils.py, utils.py.
- Review changes touching file, media, JSON, XML, CSV, OCR, or data parsing; examples from the scan include docs/bugs/p2-python-http-call-without-timeout-3955c83cfecd63ea.md, tests/testutils.py, utils.py.

## Maintenance Notes

- See `SECURITY.md` for vulnerability reporting and safe research guidance.
- See `VISION.md` for project direction and contribution guardrails.
- See `docs/plans/2026-06-08-dstl-data-loader-baseline.md` for the current
  data-loader reliability baseline.
- See `docs/plans/2026-06-09-dstl-https-download-guard.md` for the HTTPS
  download URL guard.
- See `docs/plans/2026-06-09-dstl-kaggle-host-download-guard.md` for the
  Kaggle host download guard.
- See `docs/plans/2026-06-09-dstl-archive-allowlist.md` for the DSTL archive
  filename allow-list.
- See `docs/plans/2026-06-09-dstl-zip-symlink-guard.md` for the zip symlink
  member extraction guard.
- See `docs/plans/2026-06-09-dstl-direct-credential-validation.md` for direct
  credential validation before requests.
- See `docs/plans/2026-06-09-dstl-url-credential-guard.md` for embedded URL
  credential rejection before requests.

## Contributing

Keep changes small and tied to the project that is already present in this repository. For code changes, document the toolchain used, avoid committing generated dependency directories or local configuration, and update this README when setup or verification steps change.
