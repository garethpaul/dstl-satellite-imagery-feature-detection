#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CHECK_PLAN="$ROOT_DIR/docs/plans/2026-06-08-dstl-check-wrapper.md"
HTTPS_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-https-download-guard.md"
HOST_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-kaggle-host-download-guard.md"
ARCHIVE_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-archive-allowlist.md"
SYMLINK_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-zip-symlink-guard.md"
DIRECT_CREDENTIAL_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-direct-credential-validation.md"
URL_CREDENTIAL_PLAN="$ROOT_DIR/docs/plans/2026-06-09-dstl-url-credential-guard.md"

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
  "utils.py" \
  "tests/testutils.py" \
  "docs/plans/2026-06-08-dstl-check-wrapper.md" \
  "docs/plans/2026-06-08-dstl-data-loader-baseline.md" \
  "docs/plans/2026-06-08-dstl-atomic-downloads.md" \
  "docs/plans/2026-06-09-dstl-archive-allowlist.md" \
  "docs/plans/2026-06-09-dstl-direct-credential-validation.md" \
  "docs/plans/2026-06-09-dstl-url-credential-guard.md" \
  "docs/plans/2026-06-09-dstl-kaggle-host-download-guard.md" \
  "docs/plans/2026-06-09-dstl-https-download-guard.md" \
  "docs/plans/2026-06-09-dstl-zip-symlink-guard.md" \
  "docs/bugs/p2-python-http-call-without-timeout-3955c83cfecd63ea.md"; do
  require_file "$path"
done

python3 -m py_compile "$ROOT_DIR/utils.py" "$ROOT_DIR/tests/testutils.py"
python3 -m unittest discover -s "$ROOT_DIR/tests" -p "test*.py"

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
