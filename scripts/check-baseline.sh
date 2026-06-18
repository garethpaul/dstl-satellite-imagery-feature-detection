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
TARGET_COLLISION_PLAN="$ROOT_DIR/docs/plans/2026-06-13-dstl-archive-target-collisions.md"
DESTINATION_RACE_PLAN="$ROOT_DIR/docs/plans/2026-06-13-dstl-archive-destination-race.md"
PREFIX_COLLISION_PLAN="$ROOT_DIR/docs/plans/2026-06-13-dstl-archive-prefix-collisions.md"
EXISTING_TYPE_PLAN="$ROOT_DIR/docs/plans/2026-06-14-dstl-existing-target-types.md"
MAKE_ROOT_PLAN="$ROOT_DIR/docs/plans/2026-06-14-dstl-make-root-override-protection.md"
DATASET_VERIFICATION="$ROOT_DIR/DATASET_VERIFICATION.md"
DATASET_VERIFICATION_PLAN="$ROOT_DIR/docs/plans/2026-06-14-dstl-dataset-integration-verification.md"
ROOT_SYMLINK_PLAN="$ROOT_DIR/docs/plans/2026-06-15-001-dstl-extraction-root-symlink.md"
DOWNLOAD_ROOT_PLAN="$ROOT_DIR/docs/plans/2026-06-15-descriptor-rooted-downloads.md"
DOWNLOAD_NO_CLOBBER_PLAN="$ROOT_DIR/docs/plans/2026-06-15-download-finalization-no-clobber.md"
DOWNLOAD_PARTIAL_ISOLATION_PLAN="$ROOT_DIR/docs/plans/2026-06-15-download-partial-isolation.md"
DOWNLOAD_ROLLBACK_PLAN="$ROOT_DIR/docs/plans/2026-06-15-download-finalization-rollback.md"
POST_PUBLICATION_ROOT_PLAN="$ROOT_DIR/docs/plans/2026-06-15-post-publication-download-root-check.md"
RESPONSE_CLOSE_ROLLBACK_PLAN="$ROOT_DIR/docs/plans/2026-06-15-download-response-close-rollback.md"
RUFF_REFRESH_PLAN="$ROOT_DIR/docs/plans/2026-06-18-ruff-patch-refresh.md"
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
  "DATASET_VERIFICATION.md" \
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
  "docs/plans/2026-06-13-dstl-archive-target-collisions.md" \
  "docs/plans/2026-06-13-dstl-archive-destination-race.md" \
  "docs/plans/2026-06-13-dstl-archive-prefix-collisions.md" \
  "docs/plans/2026-06-14-dstl-existing-target-types.md" \
  "docs/plans/2026-06-14-dstl-make-root-override-protection.md" \
  "docs/plans/2026-06-14-dstl-dataset-integration-verification.md" \
  "docs/plans/2026-06-15-001-dstl-extraction-root-symlink.md" \
  "docs/plans/2026-06-15-descriptor-rooted-downloads.md" \
  "docs/plans/2026-06-15-download-finalization-no-clobber.md" \
  "docs/plans/2026-06-15-download-partial-isolation.md" \
  "docs/plans/2026-06-15-download-finalization-rollback.md" \
  "docs/plans/2026-06-15-post-publication-download-root-check.md" \
  "docs/plans/2026-06-15-download-response-close-rollback.md" \
  "docs/plans/2026-06-18-ruff-patch-refresh.md" \
  "docs/bugs/p2-python-http-call-without-timeout-3955c83cfecd63ea.md"; do
  require_file "$path"
done

for dataset_contract in \
  "Commit: pending implementation commit" \
  "Pull request: pending" \
  "Evidence status: not run" \
  "private competition-authorized environment" \
  "Required sanitized evidence" \
  "Use only \`pass\`, \`fail\`, \`blocked\`, or \`not run\`" \
  "A unit test, source check, compile, lint, or dependency audit cannot mark an" \
  "No credentialed Kaggle download, competition archive extraction, private"; do
  if ! grep -Fq "$dataset_contract" "$DATASET_VERIFICATION"; then
    printf '%s\n' "Dataset verification matrix contract is missing: $dataset_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Ec '^\| [0-9]+ \|' "$DATASET_VERIFICATION")" -ne 14 ] ||
  [ "$(grep -Ec '^\| [0-9]+ \|.*\| not run \|$' "$DATASET_VERIFICATION")" -ne 14 ]; then
  printf '%s\n' "Dataset verification matrix must retain 14 explicitly not-run scenarios." >&2
  exit 1
fi

for dataset_scenario in \
  "Isolated environment setup" \
  "Missing credential preflight" \
  "Valid credential preflight" \
  "Cached archive reuse" \
  "Bounded Kaggle download" \
  "Invalid download payload" \
  "Archive member preflight" \
  "Safe archive extraction" \
  "Destination collision rejection" \
  "Destination race containment" \
  "Dataset archive inventory" \
  "Extracted dataset inventory" \
  "Resource budget enforcement" \
  "Loader smoke behavior"; do
  if [ "$(grep -Fc "| $dataset_scenario |" "$DATASET_VERIFICATION")" -ne 1 ]; then
    printf '%s\n' "Dataset verification scenario is missing or duplicated: $dataset_scenario" >&2
    exit 1
  fi
done

for dataset_guidance in \
  "DATASET_VERIFICATION.md" \
  "private authorized environment" \
  "sanitized" \
  "size buckets"; do
  if ! grep -Fq "$dataset_guidance" "$ROOT_DIR/README.md"; then
    printf '%s\n' "README dataset verification guidance is missing: $dataset_guidance" >&2
    exit 1
  fi
done

if ! grep -Fq "Keep exact-head credentialed download, private dataset, and loader evidence" "$ROOT_DIR/VISION.md" ||
  ! grep -Fq "Credentialed download, extraction, private dataset, and loader claims require" "$ROOT_DIR/SECURITY.md" ||
  ! grep -Fq "Added an exact-head DSTL dataset integration verification matrix" "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' "Project guidance must retain the DSTL dataset evidence boundary." >&2
  exit 1
fi

for dataset_plan_contract in \
  "status: completed" \
  "## Status: Completed" \
  "## Work Completed" \
  "## Verification Completed" \
  "Python 3.12.8 and Python 3.14.0" \
  "Twelve isolated hostile documentation mutations were rejected" \
  "all 14"; do
  if ! grep -Fq "$dataset_plan_contract" "$DATASET_VERIFICATION_PLAN"; then
    printf '%s\n' "Dataset verification plan must record completed evidence: $dataset_plan_contract" >&2
    exit 1
  fi
done

SAFE_ZIP_MEMBERS=$(awk '
  /^def safe_zip_members\(/ { capture = 1 }
  capture && /^def / && $0 !~ /^def safe_zip_members\(/ { exit }
  capture { print }
' "$ROOT_DIR/utils.py")

for payload_contract in \
  "def require_valid_zip_file(source):" \
  "require_valid_zip_file(handle)" \
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

if ! grep -Fq "status: completed" "$TARGET_COLLISION_PLAN" ||
  ! grep -Fq "make check" "$TARGET_COLLISION_PLAN" ||
  ! grep -Fq "Removing collision rejection failed" "$TARGET_COLLISION_PLAN" ||
  ! grep -Fq "Removing platform case normalization failed" "$TARGET_COLLISION_PLAN" ||
  ! grep -Fq "no known" "$TARGET_COLLISION_PLAN"; then
  printf '%s\n' "Archive target collision plan must record completed verification." >&2
  exit 1
fi

if ! grep -Fq "non-empty ZIP archive" "$ROOT_DIR/README.md" ||
  ! grep -Fq "non-empty ZIP archives" "$ROOT_DIR/SECURITY.md"; then
  printf '%s\n' "README and SECURITY must document ZIP payload validation." >&2
  exit 1
fi

for download_path_contract in \
  "def open_cached_download" \
  "os.O_RDONLY | os.O_NOFOLLOW" \
  "os.unlink(partial_name, dir_fd=root_fd)" \
  "os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW" \
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
  'override ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))' \
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

for make_root_plan_contract in \
  "status: completed" \
  "## Status: Completed" \
  "## Work Completed" \
  "## Verification Completed" \
  "no known vulnerabilities" \
  "Three isolated hostile assignment mutations were rejected"; do
  if ! grep -Fq "$make_root_plan_contract" "$MAKE_ROOT_PLAN"; then
    printf '%s\n' "Make-root plan must record completed evidence: $make_root_plan_contract" >&2
    exit 1
  fi
done

for dependency_contract in \
  "requests==2.34.2" \
  "pip-audit==2.10.0" \
  "ruff==0.15.16"; do
  if ! grep -Fq "$dependency_contract" "$ROOT_DIR/requirements.txt" "$ROOT_DIR/requirements-dev.txt"; then
    printf '%s\n' "Dependency contract is missing: $dependency_contract" >&2
    exit 1
  fi
done

for ruff_plan_contract in \
  "status: completed" \
  "## Status: Completed" \
  "## Work Completed" \
  "## Verification Completed" \
  "Ruff 0.15.16" \
  "Preserved Requests 2.34.2 and pip-audit 2.10.0 exactly" \
  "Five isolated dependency-contract mutations were rejected"; do
  if ! grep -Fq "$ruff_plan_contract" "$RUFF_REFRESH_PLAN"; then
    printf '%s\n' "Ruff refresh plan must record completed evidence: $ruff_plan_contract" >&2
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

if ! grep -Fq 'partial_name = ".{0}.{1}.part".format(filename, secrets.token_hex(8))' "$ROOT_DIR/utils.py" ||
  ! grep -Fq 'src_dir_fd=root_fd' "$ROOT_DIR/utils.py" ||
  ! grep -Fq 'dst_dir_fd=root_fd' "$ROOT_DIR/utils.py" ||
  ! grep -Fq "test_download_removes_partial_file_on_stream_failure" "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Downloader must write atomically and test interrupted streams." >&2
  exit 1
fi

if grep -Eq '^[[:space:]]*partial_name = filename \+ "\.part"$' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'legacy_partial_name = filename + ".part"' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'test_concurrent_downloads_do_not_share_partial_files' "$ROOT_DIR/tests/testutils.py" || \
  [ "$(grep -Fc 'threading.Event()' "$ROOT_DIR/tests/testutils.py")" -lt 4 ] || \
  ! grep -Fq 'self.assertIsInstance(errors.get("second"), FileExistsError)' "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Concurrent downloads must use isolated partial names with regression coverage." >&2
  exit 1
fi

if ! grep -Fq 'status: completed' "$DOWNLOAD_PARTIAL_ISOLATION_PLAN" || \
  ! grep -Fq 'make check' "$DOWNLOAD_PARTIAL_ISOLATION_PLAN" || \
  ! grep -Fq 'Six isolated hostile mutations were rejected' "$DOWNLOAD_PARTIAL_ISOLATION_PLAN" || \
  ! grep -Fq 'external working directory' "$DOWNLOAD_PARTIAL_ISOLATION_PLAN"; then
  printf '%s\n' "Download partial isolation plan must record completed verification." >&2
  exit 1
fi

if ! grep -Fq 'secret-suffixed partial names isolate concurrent downloads' "$ROOT_DIR/README.md" || \
  ! grep -Fq 'secret-suffixed partial names isolate concurrent downloads' "$ROOT_DIR/SECURITY.md" || \
  ! grep -Fq 'secret-suffixed partial names isolate concurrent downloads' "$ROOT_DIR/VISION.md" || \
  ! grep -Fq 'secret-suffixed partial names isolate concurrent downloads' "$AGENTS" || \
  ! grep -Fq 'Isolated concurrent downloads with secret-suffixed partial names' "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' "Project guidance must document concurrent download partial isolation." >&2
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

if ! grep -Fq "seen_targets = set()" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "os.path.normcase(target_path)" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "colliding target paths" "$ROOT_DIR/utils.py" ||
  ! grep -Fq "test_unzip_rejects_colliding_target_paths_before_writing" "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Zip extraction must reject colliding normalized targets before writing files." >&2
  exit 1
fi

if [ "$(printf '%s\n' "$SAFE_ZIP_MEMBERS" | grep -Fc "file_targets = set()")" -ne 1 ] ||
  [ "$(printf '%s\n' "$SAFE_ZIP_MEMBERS" | grep -Fc "required_directories = set()")" -ne 1 ] ||
  [ "$(printf '%s\n' "$SAFE_ZIP_MEMBERS" | grep -Fc "file and directory prefix collisions")" -ne 2 ] ||
  ! grep -Fq "test_unzip_rejects_file_directory_prefix_collisions_before_writing" "$ROOT_DIR/tests/testutils.py" ||
  [ "$(grep -Fc '(("nested", "file"), ("nested/file.txt", "child"))' "$ROOT_DIR/tests/testutils.py")" -ne 1 ] ||
  [ "$(grep -Fc '(("nested/file.txt", "child"), ("nested", "file"))' "$ROOT_DIR/tests/testutils.py")" -ne 1 ]; then
  printf '%s\n' "Zip extraction must reject file and directory prefix collisions in either order." >&2
  exit 1
fi

if [ "$(printf '%s\n' "$SAFE_ZIP_MEMBERS" | grep -Fc "must_be_directory =")" -ne 1 ] ||
  [ "$(printf '%s\n' "$SAFE_ZIP_MEMBERS" | grep -Fc "os.path.lexists(current_path)")" -ne 1 ] ||
  [ "$(printf '%s\n' "$SAFE_ZIP_MEMBERS" | grep -Fc "destination type collision")" -ne 1 ] ||
  ! grep -Fq "test_unzip_rejects_existing_destination_type_collisions_before_writing" "$ROOT_DIR/tests/testutils.py" ||
  ! grep -Fq 'collisions = ("directory-at-file-target", "file-at-required-directory")' "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Zip extraction must preflight existing destination type collisions." >&2
  exit 1
fi

for extraction_contract in \
  "def require_secure_extraction_support" \
  "os.O_DIRECTORY | os.O_NOFOLLOW" \
  "def open_output_root" \
  "def extract_zip_member" \
  "os.O_EXCL | os.O_NOFOLLOW" \
  "os.fsync(target.fileno())" \
  "src_dir_fd=parent_fd" \
  "os.unlink(temporary_name, dir_fd=parent_fd)" \
  "test_unzip_rejects_destination_symlink_race" \
  "test_unzip_securely_creates_missing_output_root" \
  "test_unzip_atomically_replaces_existing_regular_file" \
  "test_unzip_preserves_existing_file_when_replace_fails" \
  "test_unzip_fails_closed_without_no_follow_support"; do
  if ! grep -Fq "$extraction_contract" "$ROOT_DIR/utils.py" "$ROOT_DIR/tests/testutils.py"; then
    printf '%s\n' "Descriptor-rooted extraction contract is missing: $extraction_contract" >&2
    exit 1
  fi
done

if grep -Fq "zip_ref.extract(member, output_dir)" "$ROOT_DIR/utils.py"; then
  printf '%s\n' "Zip extraction must not return to pathname-based ZipFile.extract." >&2
  exit 1
fi

if [ "$(grep -Fc 'os.path.abspath(output_dir)' "$ROOT_DIR/utils.py")" -ne 2 ] || \
  grep -Fq 'os.path.realpath(output_dir)' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'test_unzip_rejects_symlinked_output_root' "$ROOT_DIR/tests/testutils.py" || \
  ! grep -Fq 'os.symlink(outside_dir, output_dir)' "$ROOT_DIR/tests/testutils.py" || \
  ! grep -Fq 'self.assertFalse(os.path.exists(os.path.join(outside_dir, "file.txt")))' "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Descriptor-rooted extraction must reject symlinked output roots before writing." >&2
  exit 1
fi

for download_root_contract in \
  "output_root = os.path.abspath(output_dir or os.getcwd())" \
  "def require_secure_descriptor_support" \
  "def open_download_root" \
  "def require_download_root_identity" \
  "def open_cached_download" \
  "os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW" \
  "os.unlink(partial_name, dir_fd=root_fd)" \
  "src_dir_fd=root_fd" \
  "dst_dir_fd=root_fd" \
  "test_download_rejects_symlinked_output_root_before_request" \
  "test_download_rejects_replaced_output_root_before_writing" \
  "test_download_rejects_replaced_output_root_during_cache_validation"; do
  if ! grep -Fq "$download_root_contract" "$ROOT_DIR/utils.py" "$ROOT_DIR/tests/testutils.py"; then
    printf '%s\n' "Descriptor-rooted download contract is missing: $download_root_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc '            require_download_root_identity(output_root, root_fd)' "$ROOT_DIR/utils.py")" -ne 4 ]; then
  printf '%s\n' "Descriptor-rooted downloads must verify output-root identity for cache reuse, after the request, before publication, and after publication." >&2
  exit 1
fi

if ! grep -Fq 'Status: Completed' "$DOWNLOAD_ROOT_PLAN" || \
  ! grep -Fq '40 offline tests' "$DOWNLOAD_ROOT_PLAN" || \
  ! grep -Fq 'hostile mutations were rejected' "$DOWNLOAD_ROOT_PLAN" || \
  ! grep -Fq 'external working directory' "$DOWNLOAD_ROOT_PLAN"; then
  printf '%s\n' "Descriptor-rooted download plan must record completed verification." >&2
  exit 1
fi

if ! grep -Fq 'Downloads hold a descriptor-verified output root' "$ROOT_DIR/README.md" || \
  ! grep -Fq 'Download roots must remain descriptor-identical' "$ROOT_DIR/SECURITY.md" || \
  ! grep -Fq 'Bind download publication to a descriptor-verified output root' "$ROOT_DIR/VISION.md" || \
  ! grep -Fq 'Bound download cache and publication operations to a descriptor-verified output root' "$ROOT_DIR/CHANGES.md" || \
  ! grep -Fq 'Preserve descriptor-rooted download cache and publication operations' "$AGENTS"; then
  printf '%s\n' "Project guidance must document descriptor-rooted downloads." >&2
  exit 1
fi

if grep -Fq 'os.rename(' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'os.link(' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'def require_secure_download_support' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'os.link not in os.supports_dir_fd' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'os.rename not in os.supports_dir_fd' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'test_download_does_not_clobber_raced_final_file' "$ROOT_DIR/tests/testutils.py" || \
  ! grep -Fq 'self.assertEqual(b"competing download", handle.read())' "$ROOT_DIR/tests/testutils.py" || \
  ! grep -Fq 'self.assertEqual([], [name for name in os.listdir(tmpdir) if name.endswith(".part")])' "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Download finalization must fail closed without clobbering raced destination files." >&2
  exit 1
fi

if ! grep -Fq 'Validated downloads publish without replacing a raced final file' "$ROOT_DIR/README.md" || \
  ! grep -Fq 'Download publication must fail when the final name races into existence' "$ROOT_DIR/SECURITY.md" || \
  ! grep -Fq 'Publish validated downloads without clobbering raced destinations' "$ROOT_DIR/VISION.md" || \
  ! grep -Fq 'Prevented download finalization from clobbering raced destination files' "$ROOT_DIR/CHANGES.md" || \
  ! grep -Fq 'Preserve no-clobber download finalization' "$AGENTS"; then
  printf '%s\n' "Project guidance must document no-clobber download publication." >&2
  exit 1
fi

for download_no_clobber_contract in \
  'status: completed' \
  '## Status: Completed' \
  '## Verification Completed' \
  'hostile mutations were rejected'; do
  if ! grep -Fq "$download_no_clobber_contract" "$DOWNLOAD_NO_CLOBBER_PLAN"; then
    printf '%s\n' "Download no-clobber plan must record completed evidence: $download_no_clobber_contract" >&2
    exit 1
  fi
done

for download_rollback_contract in \
  'status: completed' \
  '## Status: Completed' \
  '## Verification Completed' \
  'hostile mutations were rejected'; do
  if ! grep -Fq "$download_rollback_contract" "$DOWNLOAD_ROLLBACK_PLAN"; then
    printf '%s\n' "Download finalization rollback plan must record completed evidence: $download_rollback_contract" >&2
    exit 1
  fi
done

if ! grep -Fq 'published_final = False' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'published_final = True' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'if published_final:' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'os.unlink(filename, dir_fd=root_fd)' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'test_download_rolls_back_final_file_when_partial_cleanup_fails' "$ROOT_DIR/tests/testutils.py" || \
  ! grep -Fq 'self.assertFalse(os.path.lexists(filepath))' "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Download finalization failures must roll back the final name owned by this invocation." >&2
  exit 1
fi

if ! grep -Fq 'If post-publication partial cleanup fails' "$ROOT_DIR/README.md" || \
  ! grep -Fq 'If cleanup fails after publication' "$ROOT_DIR/SECURITY.md" || \
  ! grep -Fq 'Roll back owned final download names' "$ROOT_DIR/VISION.md" || \
  ! grep -Fq 'Rolled back owned final download names' "$ROOT_DIR/CHANGES.md" || \
  ! grep -Fq 'Preserve rollback of the invocation-owned final download name' "$AGENTS"; then
  printf '%s\n' "Project guidance must document failed download publication rollback." >&2
  exit 1
fi

python3 - "$ROOT_DIR/utils.py" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text()
download = source[source.index("def download_url("):]
order = [
    "published_final = True",
    "os.unlink(partial_name, dir_fd=root_fd)",
    "if published_final:",
    "os.unlink(filename, dir_fd=root_fd)",
    "os.unlink(partial_name, dir_fd=root_fd)",
]
positions = []
start = 0
for token in order:
    position = download.index(token, start)
    positions.append(position)
    start = position + len(token)
if positions != sorted(positions):
    raise SystemExit("Owned final publication must be rolled back before partial cleanup is retried.")
PY

for post_publication_root_contract in \
  'status: completed' \
  '## Status: Completed' \
  '## Verification Completed' \
  'hostile mutations were rejected'; do
  if ! grep -Fq "$post_publication_root_contract" "$POST_PUBLICATION_ROOT_PLAN"; then
    printf '%s\n' "Post-publication root plan must record completed evidence: $post_publication_root_contract" >&2
    exit 1
  fi
done

python3 - "$ROOT_DIR/utils.py" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text()
download = source[source.index("def download_url("):]
publication = download.index("published_final = True")
partial_cleanup = download.index("os.unlink(partial_name, dir_fd=root_fd)", publication)
post_publication_check = download.index(
    "require_download_root_identity(output_root, root_fd)", partial_cleanup
)
rollback = download.index("if published_final:", post_publication_check)
if not publication < partial_cleanup < post_publication_check < rollback:
    raise SystemExit("Output-root identity must be checked inside publication rollback scope.")
PY

if ! grep -Fq 'test_download_rolls_back_when_output_root_changes_after_publication' "$ROOT_DIR/tests/testutils.py" || \
  ! grep -Fq 'self.assertEqual(3, identity_checks)' "$ROOT_DIR/tests/testutils.py" || \
  ! grep -Fq 'self.assertFalse(os.path.lexists(os.path.join(moved_dir, filename)))' "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Post-publication output-root races must fail closed and roll back owned files." >&2
  exit 1
fi

if ! grep -Fq 'revalidated after publication' "$ROOT_DIR/README.md" || \
  ! grep -Fq 'revalidated after final publication' "$ROOT_DIR/SECURITY.md" || \
  ! grep -Fq 'Revalidate the download root after final publication' "$ROOT_DIR/VISION.md" || \
  ! grep -Fq 'Revalidated download-root identity after final publication' "$ROOT_DIR/CHANGES.md" || \
  ! grep -Fq 'Preserve post-publication download-root identity checks' "$AGENTS"; then
  printf '%s\n' "Project guidance must document post-publication download-root verification." >&2
  exit 1
fi

for response_close_contract in \
  'status: completed' \
  '## Status: Completed' \
  '## Verification Completed' \
  'hostile mutations were rejected' \
  'b0e479d06f99967d39b704e7e2ae176960719511' \
  'pull-request workflow run `27572525408`' \
  'No credentialed Kaggle request'; do
  if ! grep -Fq "$response_close_contract" "$RESPONSE_CLOSE_ROLLBACK_PLAN"; then
    printf '%s\n' "Response-close rollback plan must record completed evidence: $response_close_contract" >&2
    exit 1
  fi
done

if ! grep -Fq 'response_close_attempted = False' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'response_close_attempted = True' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'if not response_close_attempted:' "$ROOT_DIR/utils.py" || \
  ! grep -Fq 'test_download_rolls_back_final_file_when_response_close_fails' "$ROOT_DIR/tests/testutils.py" || \
  ! grep -Fq 'test_download_rolls_back_when_output_root_changes_during_response_close' "$ROOT_DIR/tests/testutils.py"; then
  printf '%s\n' "Response finalization must remain inside owned-publication rollback and root verification." >&2
  exit 1
fi

python3 - "$ROOT_DIR/utils.py" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text()
download = source[source.index("def download_url("):]
publication = download.index("published_final = True")
close_attempt = download.index("response_close_attempted = True", publication)
close_call = download.index("close()", close_attempt)
final_identity = download.index(
    "require_download_root_identity(output_root, root_fd)", close_call
)
rollback = download.index("if published_final:", final_identity)
fallback_close = download.index("if not response_close_attempted:", rollback)
if not publication < close_attempt < close_call < final_identity < rollback < fallback_close:
    raise SystemExit("Response close and final root verification must remain inside rollback scope.")
PY

if ! grep -Fq 'Successful downloads close the response inside the publication rollback scope' "$ROOT_DIR/README.md" || \
  ! grep -Fq 'Response finalization failures must roll back an invocation-owned published download' "$ROOT_DIR/SECURITY.md" || \
  ! grep -Fq 'Keep response close and final root verification inside download rollback' "$ROOT_DIR/VISION.md" || \
  ! grep -Fq 'Rolled back published downloads when response finalization failed' "$ROOT_DIR/CHANGES.md" || \
  ! grep -Fq 'Preserve response close and final root verification inside publication rollback' "$AGENTS"; then
  printf '%s\n' "Project guidance must document response-close publication rollback." >&2
  exit 1
fi

if ! grep -Fq 'status: completed' "$ROOT_SYMLINK_PLAN" || \
  ! grep -Fq 'make check' "$ROOT_SYMLINK_PLAN" || \
  ! grep -Fq 'hostile mutations' "$ROOT_SYMLINK_PLAN"; then
  printf '%s\n' "Extraction-root symlink plan must record completed verification." >&2
  exit 1
fi

if ! grep -Fq 'Symlinked extraction roots are rejected before member writes' "$ROOT_DIR/README.md" || \
  ! grep -Fq 'Symlinked extraction roots must be rejected before descriptor traversal' "$ROOT_DIR/SECURITY.md" || \
  ! grep -Fq 'Reject symlinked extraction roots before descriptor traversal' "$ROOT_DIR/VISION.md" || \
  ! grep -Fq 'Rejected symlinked extraction roots before descriptor traversal' "$ROOT_DIR/CHANGES.md" || \
  ! grep -Fq 'Preserve rejection of symlinked extraction roots' "$AGENTS"; then
  printf '%s\n' "Project guidance must document extraction-root symlink rejection." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$DESTINATION_RACE_PLAN" ||
  ! grep -Fq "Python 3.12.8 and Python 3.14.0" "$DESTINATION_RACE_PLAN" ||
  ! grep -Fq "hostile mutations were rejected" "$DESTINATION_RACE_PLAN" ||
  ! grep -Fq "no live Kaggle" "$DESTINATION_RACE_PLAN"; then
  printf '%s\n' "Archive destination race plan must record completed verification." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$PREFIX_COLLISION_PLAN" ||
  ! grep -Fq "make check" "$PREFIX_COLLISION_PLAN" ||
  ! grep -Fq "hostile mutations were rejected" "$PREFIX_COLLISION_PLAN" ||
  ! grep -Fq "no live Kaggle" "$PREFIX_COLLISION_PLAN"; then
  printf '%s\n' "Archive prefix collision plan must record completed verification." >&2
  exit 1
fi


if ! grep -Fq "status: completed" "$EXISTING_TYPE_PLAN" ||
  ! grep -Fq "make check" "$EXISTING_TYPE_PLAN" ||
  ! grep -Fq "hostile mutations" "$EXISTING_TYPE_PLAN"; then
  printf '%s\n' "Existing destination type plan must record completed verification." >&2
  exit 1
fi

if ! grep -Fq "descriptor-rooted extraction" "$ROOT_DIR/README.md" ||
  ! grep -Fq "descriptor-relative no-follow extraction" "$ROOT_DIR/SECURITY.md" ||
  ! grep -Fq "Close destination path races with descriptor-rooted extraction" "$ROOT_DIR/VISION.md" ||
  ! grep -Fq "descriptor-rooted archive extraction" "$AGENTS" ||
  ! grep -Fq "Closed archive destination path races" "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' "Project guidance must document descriptor-rooted archive extraction." >&2
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

if ! grep -Fq "colliding destination paths" "$ROOT_DIR/README.md" ||
  ! grep -Fq "colliding destination paths" "$ROOT_DIR/SECURITY.md"; then
  printf '%s\n' "README and SECURITY must document archive target collision rejection." >&2
  exit 1
fi

if ! grep -Fq "file and directory prefix collisions" "$ROOT_DIR/README.md" ||
  ! grep -Fq "file and directory prefix collisions" "$ROOT_DIR/SECURITY.md" ||
  ! grep -Fq "file-directory prefix collisions" "$ROOT_DIR/VISION.md" ||
  ! grep -Fq "file and directory prefix collisions" "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' "Project guidance must document archive prefix collision rejection." >&2
  exit 1
fi

if ! grep -Fq "existing destination type collisions" "$ROOT_DIR/README.md" ||
  ! grep -Fq "existing destination type collisions" "$ROOT_DIR/SECURITY.md" ||
  ! grep -Fq "existing destination type collisions" "$ROOT_DIR/VISION.md" ||
  ! grep -Fq "existing destination type collisions" "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' "Project guidance must document existing destination type preflight." >&2
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
