#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PYTHON=${PYTHON:-python3}
CHECK_PLAN="$ROOT_DIR/docs/plans/2026-06-08-dstl-check-wrapper.md"
HTTPS_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-https-download-guard.md"
HOST_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-kaggle-host-download-guard.md"
ARCHIVE_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-archive-allowlist.md"
SYMLINK_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-zip-symlink-guard.md"
DIRECT_CREDENTIAL_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-direct-credential-validation.md"
URL_CREDENTIAL_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-url-credential-guard.md"
TIMEOUT_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-timeout-validation.md"
RESOURCE_PLAN="$ROOT_DIR/docs/plans/2026-06-10-dstl-resource-and-ci-limits.md"
DOWNLOAD_PATH_PLAN="$ROOT_DIR/docs/plans/2026-06-10-dstl-download-path-boundary.md"
PAYLOAD_PLAN="$ROOT_DIR/docs/plans/2026-06-12-dstl-download-payload-validation.md"
WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"
AGENTS="$ROOT_DIR/AGENTS.md"

require_file() {
  path=$1
  if [ ! -f "$ROOT_DIR/$path" ]; then
    printf '%s\n' "Required file is missing: $path" >&2
    exit 1
  fi
}

for path in \
  "README.md" \
  "Makefile" \
  "SECURITY.md" \
  "VISION.md" \
  "requirements.txt" \
  "requirements-dev.txt" \
  "pyproject.toml" \
  ".github/workflows/check.yml" \
  "utils.py" \
  "tests/testutils.py" \
  "docs/plans/2026-06-08-dstl-check-wrapper.md" \
  "docs/plans/2026-06-08-dstl-data-loader-baseline.md" \
  "docs/plans/2026-06-08-dstl-atomic-downloads.md" \
  "docs/plans/2026-06-09-dstl-archive-allowlist.md" \
  "docs/plans/2026-06-09-dstl-direct-credential-validation.md" \
  "docs/plans/2026-06-09-dstl-timeout-validation.md" \
  "docs/plans/2026-06-09-dstl-url-credential-guard.md" \
  "docs/plans/2026-06-09-dstl-kaggle-host-download-guard.md" \
  "docs/plans/2026-06-09-dstl-https-download-guard.md" \
  "docs/plans/2026-06-09-dstl-zip-symlink-guard.md" \
  "docs/plans/2026-06-10-dstl-resource-and-ci-limits.md" \
  "docs/plans/2026-06-10-dstl-download-path-boundary.md" \
  "docs/plans/2026-06-12-dstl-download-payload-validation.md" \
  "docs/bugs/p2-python-http-call-without-timeout-3955c83cfecd63ea.md"; do
  require_file "$path"
done

for payload_contract in \
  "def require_valid_zip_file(path):" \
  "require_valid_zip_file(filepath)" \
  "require_valid_zip_file(partial_path)" \
  "test_download_rejects_invalid_cached_zip_before_credentials" \
  "test_download_reuses_valid_cached_zip_before_credentials" \
  "test_download_rejects_invalid_streamed_zip_and_removes_partial_file" \
  "test_download_rejects_empty_streamed_zip"; do
  if ! grep -Fq "$payload_contract" "$ROOT_DIR/utils.py" "$ROOT_DIR/tests/testutils.py"; then
    printf '%s\n' "Download payload contract is missing: $payload_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "Status: Completed" "$PAYLOAD_PLAN" ||
  ! grep -Fq 'make check' "$PAYLOAD_PLAN"; then
  printf '%s\n' "Download payload plan must remain completed with verification recorded." >&2
  exit 1
fi

if ! grep -Fq "non-empty ZIP archive" "$ROOT_DIR/README.md" ||
  ! grep -Fq "non-empty ZIP archives" "$ROOT_DIR/SECURITY.md"; then
  printf '%s\n' "README and SECURITY must document ZIP payload validation." >&2
  exit 1
fi

for download_path_contract in \
  "os.path.lexists(filepath)" \
  "os.path.lexists(partial_path)" \
  "os.lstat(filepath).st_mode" \
  "os.O_EXCL" \
  "test_download_rejects_existing_symlink_cache_before_request" \
  "test_download_exclusively_creates_partial_file"; do
  if ! grep -Fq "$download_path_contract" "$ROOT_DIR/utils.py" "$ROOT_DIR/tests/testutils.py"; then
    printf '%s\n' "Download-path contract is missing: $download_path_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "Status: Completed" "$DOWNLOAD_PATH_PLAN" ||
  ! grep -Fq 'make check' "$DOWNLOAD_PATH_PLAN"; then
  printf '%s\n' "Download-path plan must remain completed with verification recorded." >&2
  exit 1
fi

for make_contract in \
  'ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))' \
  'PYTHON="$(PYTHON)" "$(ROOT)/scripts/check-baseline.sh"' \
  'cd "$(ROOT)" && $(PYTHON) -m unittest discover -s tests -p "test*.py"' \
  '$(PYTHON) -m ruff format --check "$(ROOT)"' \
  '$(PYTHON) -m ruff check "$(ROOT)"' \
  '$(PYTHON) -m pip_audit -r "$(ROOT)/requirements.txt" -r "$(ROOT)/requirements-dev.txt"'; do
  if ! grep -Fq "$make_contract" "$ROOT_DIR/Makefile"; then
    printf '%s\n' "Makefile verification contract is missing: $make_contract" >&2
    exit 1
  fi
done

for dependency_contract in \
  "requests==2.34.2" \
  "pip-audit==2.10.0" \
  "ruff==0.15.15"; do
  if ! grep -Fq "$dependency_contract" "$ROOT_DIR/requirements.txt" "$ROOT_DIR/requirements-dev.txt"; then
    printf '%s\n' "Dependency contract is missing: $dependency_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "Status: Completed" "$RESOURCE_PLAN" ||
  ! grep -Fq 'make check' "$RESOURCE_PLAN"; then
  printf '%s\n' "Resource and CI plan must remain completed with verification recorded." >&2
  exit 1
fi

for workflow_contract in \
  "permissions:" \
  "contents: read" \
  "workflow_dispatch:" \
  "cancel-in-progress: true" \
  "timeout-minutes: 10" \
  "runs-on: ubuntu-24.04" \
  "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10" \
  "actions/setup-python@a309ff8b426b58ec0e2a45f0f869d46889d02405" \
  "persist-credentials: false" \
  'python-version: ["3.10", "3.12", "3.14"]' \
  'python-version: ${{ matrix.python-version }}' \
  "run: make check"; do
  if ! grep -Fq "$workflow_contract" "$WORKFLOW"; then
    printf '%s\n' "GitHub Actions workflow must keep contract: $workflow_contract" >&2
    exit 1
  fi
done

workflow_paths=$(find "$ROOT_DIR/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print | LC_ALL=C sort)
if [ "$workflow_paths" != "$WORKFLOW" ]; then
  printf '%s\n' "The canonical check workflow must be the only GitHub Actions workflow." >&2
  exit 1
fi

if [ "$(grep -Ec '^[[:space:]]*permissions:' "$WORKFLOW")" -ne 1 ] || \
  grep -Eq 'write-all|contents:[[:space:]]*write|pull-requests:[[:space:]]*write|actions:[[:space:]]*write' "$WORKFLOW"; then
  printf '%s\n' "GitHub Actions permissions must remain globally read-only." >&2
  exit 1
fi

if [ "$(grep -Ec '^[[:space:]]*(-[[:space:]]+)?run:' "$WORKFLOW")" -ne 2 ] || \
  grep -Eq 'continue-on-error:[[:space:]]*true|if:[[:space:]]*false' "$WORKFLOW"; then
  printf '%s\n' "GitHub Actions must run exactly dependency installation and the full Make gate without bypasses." >&2
  exit 1
fi

if ! grep -Fq "Supported runtime: Python 3.10 or newer; CI covers Python 3.10, 3.12, and 3.14." "$AGENTS"; then
  printf '%s\n' "AGENTS.md must document the supported Python runtime and hosted matrix." >&2
  exit 1
fi

"$PYTHON" - "$WORKFLOW" <<'PY'
from pathlib import Path
import re
import sys

workflow = Path(sys.argv[1]).read_text(encoding="utf-8")
checkout = "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10"
setup_python = "actions/setup-python@a309ff8b426b58ec0e2a45f0f869d46889d02405"
expected_actions = [checkout, setup_python]
actions = re.findall(r"^\s*-?\s*uses:\s*([^\s#]+)", workflow, re.MULTILINE)

if actions != expected_actions:
    raise SystemExit("GitHub Actions must use exactly the two reviewed immutable action pins.")
if re.search(r"^\s*-?\s*uses:\s*[^\s#]+@v[0-9]", workflow, re.MULTILINE):
    raise SystemExit("GitHub Actions must not use release-tag action references.")
if workflow.count("persist-credentials:") != 1 or "persist-credentials: true" in workflow:
    raise SystemExit("Checkout credential persistence must be disabled exactly once.")

checkout_contract = (
    f"uses: {checkout} # v6.0.3\n"
    "        with:\n"
    "          persist-credentials: false"
)
if checkout_contract not in workflow:
    raise SystemExit("Checkout must disable credential persistence in its own with block.")
PY

if grep -Fq 'ubuntu-latest' "$WORKFLOW"; then
  printf '%s\n' "GitHub Actions must not use a floating Ubuntu runner." >&2
  exit 1
fi

for resource_contract in \
  "DEFAULT_MAX_DOWNLOAD_BYTES" \
  "DEFAULT_MAX_EXTRACTED_BYTES" \
  "DEFAULT_MAX_ARCHIVE_MEMBERS" \
  "test_download_rejects_stream_over_limit_and_removes_partial_file" \
  "test_unzip_rejects_extracted_size_over_limit" \
  "test_unzip_rejects_archive_member_count_over_limit" \
  "test_unzip_rejects_existing_symlink_in_destination_path" \
  "test_unzip_preflights_all_members_before_writing"; do
  if ! grep -Fq "$resource_contract" "$ROOT_DIR/utils.py" "$ROOT_DIR/tests/testutils.py"; then
    printf '%s\n' "Resource-limit contract is missing: $resource_contract" >&2
    exit 1
  fi
done

"$PYTHON" -m py_compile "$ROOT_DIR/utils.py" "$ROOT_DIR/tests/testutils.py"
(cd "$ROOT_DIR" && "$PYTHON" -m unittest discover -s tests -p "test*.py")

if ! grep -Fq "iter_content" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "CHUNK_SIZE" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "close()" "$ROOT_DIR/utils.py"; then
  printf '%s\n' "Downloader must stream chunks and close HTTP responses." >&2
  exit 1
fi

if ! grep -Fq "partial_path = filepath + \".part\"" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "os.replace(partial_path, filepath)" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "test_download_removes_partial_file_on_stream_failure" "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Downloader must write atomically and test interrupted streams." >&2
  exit 1
fi

if ! grep -Fq "def require_https_url" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "require_https_url(url)" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "test_download_rejects_non_https_url_before_credentials" "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Downloader must reject non-HTTPS URLs before posting credentials." >&2
  exit 1
fi

if ! grep -Fq "ALLOWED_DOWNLOAD_HOSTS" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "parsed_url.hostname" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "test_download_rejects_non_kaggle_host_before_credentials" "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Downloader must reject non-Kaggle hosts before posting credentials." >&2
  exit 1
fi

if ! grep -Fq "parsed_url.username or parsed_url.password" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "test_download_rejects_embedded_url_credentials_before_credentials" "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Downloader must reject embedded URL credentials before posting requests." >&2
  exit 1
fi

if ! grep -Fq "ALLOWED_DATA_FILES" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "def require_allowed_data_file" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "require_allowed_data_file(filename)" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "test_download_rejects_unexpected_kaggle_file_before_credentials" "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Downloader must reject unexpected DSTL archive filenames before posting credentials." >&2
  exit 1
fi

if ! grep -Fq "stat.S_ISLNK" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "Refusing to extract zip symlink member" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "test_unzip_rejects_symlink_members" "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Zip extraction must reject symlink members before writing files." >&2
  exit 1
fi

if ! grep -Fq "def normalize_credentials" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "normalize_credentials(credentials)" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "test_download_rejects_blank_supplied_credentials_before_request" "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Downloader must validate supplied credentials before posting requests." >&2
  exit 1
fi

if ! grep -Fq "def normalize_timeout" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "math.isfinite" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "timeout = normalize_timeout(timeout)" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "test_download_rejects_invalid_timeout_before_request" "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Downloader must validate timeout values before posting requests." >&2
  exit 1
fi

python3 - "$ROOT_DIR/utils.py" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text()
download = source[source.index("def download_url("):]
order = [
    "require_https_url(url)",
    "filename = filename_from_url(url)",
    "require_allowed_data_file(filename)",
    "credentials = (",
]
positions = [download.index(token) for token in order]
if positions != sorted(positions):
    raise SystemExit("Download URL, filename, and archive allowlist checks must run before credential loading.")
PY

python3 - "$ROOT_DIR/utils.py" <<'PY'
import ast
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
tree = ast.parse(path.read_text(), filename=str(path))
methods = {"delete", "get", "head", "options", "patch", "post", "put", "request"}
violations = []

for node in ast.walk(tree):
    if not isinstance(node, ast.Call) or not isinstance(node.func, ast.Attribute):
        continue
    if node.func.attr not in methods:
        continue
    if not isinstance(node.func.value, ast.Name):
        continue
    if node.func.value.id not in {"requests", "client", "session"}:
        continue
    if not any(keyword.arg == "timeout" for keyword in node.keywords):
        violations.append((node.lineno, node.func.attr))

if violations:
    details = ", ".join(f"line {line} {method}()" for line, method in violations)
    raise SystemExit(f"HTTP calls must pass timeout: {details}")
PY

if ! grep -Fq "status: completed" "$ROOT_DIR/docs/plans/2026-06-08-dstl-data-loader-baseline.md"; then
  printf '%s\n' "Plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$CHECK_PLAN"; then
  printf '%s\n' "Check wrapper plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$ROOT_DIR/docs/plans/2026-06-08-dstl-atomic-downloads.md"; then
  printf '%s\n' "Atomic download plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$HTTPS_PLAN"; then
  printf '%s\n' "HTTPS download guard plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$HOST_PLAN"; then
  printf '%s\n' "Kaggle host download guard plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$ARCHIVE_PLAN"; then
  printf '%s\n' "DSTL archive allowlist plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ARCHIVE_PLAN"; then
  printf '%s\n' "DSTL archive allowlist plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$SYMLINK_PLAN"; then
  printf '%s\n' "DSTL zip symlink guard plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$SYMLINK_PLAN"; then
  printf '%s\n' "DSTL zip symlink guard plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$DIRECT_CREDENTIAL_PLAN"; then
  printf '%s\n' "Direct credential validation plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$DIRECT_CREDENTIAL_PLAN"; then
  printf '%s\n' "Direct credential validation plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$URL_CREDENTIAL_PLAN"; then
  printf '%s\n' "URL credential guard plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$URL_CREDENTIAL_PLAN"; then
  printf '%s\n' "URL credential guard plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$TIMEOUT_PLAN"; then
  printf '%s\n' "Timeout validation plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$TIMEOUT_PLAN"; then
  printf '%s\n' "Timeout validation plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "python3 -m unittest discover" "$ROOT_DIR/README.md" ||
  ! grep -Fq "kaggle_credentials.ini" "$ROOT_DIR/README.md" ||
  ! grep -Fq "requirements.txt" "$ROOT_DIR/README.md" ||
  ! grep -Fq "make check" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document tests, Kaggle credentials, requirements, and make check." >&2
  exit 1
fi

if ! grep -Fq "HTTPS download URLs" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document HTTPS download URL enforcement." >&2
  exit 1
fi

if ! grep -Fq "Kaggle hosts" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document Kaggle host enforcement." >&2
  exit 1
fi

if ! grep -Fq "checked-in DSTL archive list" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document DSTL archive filename enforcement." >&2
  exit 1
fi

if ! grep -Fq "symlink members" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document zip symlink member rejection." >&2
  exit 1
fi

if ! grep -Fq "supplied credentials are normalized" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document direct credential validation." >&2
  exit 1
fi

if ! grep -Fq "embedded URL credentials" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document embedded URL credential rejection." >&2
  exit 1
fi

if ! grep -Fq "positive finite timeout" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document positive finite download timeout validation." >&2
  exit 1
fi

if ! grep -Fq "checked-in DSTL archive filename list" "$ROOT_DIR/SECURITY.md"; then
  printf '%s\n' "SECURITY must document DSTL archive filename enforcement." >&2
  exit 1
fi

if ! grep -Fq "symlink members" "$ROOT_DIR/SECURITY.md"; then
  printf '%s\n' "SECURITY must document zip symlink member rejection." >&2
  exit 1
fi

if ! grep -Fq "Supplied Kaggle credentials are normalized" "$ROOT_DIR/SECURITY.md"; then
  printf '%s\n' "SECURITY must document direct credential validation." >&2
  exit 1
fi

if ! grep -Fq "embedded URL credentials" "$ROOT_DIR/SECURITY.md"; then
  printf '%s\n' "SECURITY must document embedded URL credential rejection." >&2
  exit 1
fi

if ! grep -Fq "positive finite timeout" "$ROOT_DIR/SECURITY.md"; then
  printf '%s\n' "SECURITY must document positive finite download timeout validation." >&2
  exit 1
fi

if ! grep -Fq "check: verify" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must expose make check as the repository verification wrapper." >&2
  exit 1
fi

if ! grep -Fq "build:" "$ROOT_DIR/Makefile" ||
  ! grep -Fq "verify: lint test build" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must expose build and include it in verification." >&2
  exit 1
fi

if ! grep -Fq "Resolved" "$ROOT_DIR/docs/bugs/p2-python-http-call-without-timeout-3955c83cfecd63ea.md"; then
  printf '%s\n' "Timeout bug note must include its resolution." >&2
  exit 1
fi

printf '%s\n' "DSTL data loader baseline checks passed."
