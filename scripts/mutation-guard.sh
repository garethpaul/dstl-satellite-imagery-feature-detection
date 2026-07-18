#!/usr/bin/env sh
# Behavioural guard for the offline test suite.
#
# Every other verification step in this repository reads a *representation* of
# the code (a grep for a substring, a pinned test name, a documented claim).
# None of them observe whether the test suite still *detects* anything: a suite
# whose assertions have been neutered keeps every pinned name and every pinned
# assertion source line byte-identical, reports "OK", and exits 0.
#
# This guard closes that gap by construction rather than by pinning. It copies
# the tree to a scratch directory, plants a real defect in the copy, runs the
# real suite, and fails if the suite still passes. A suite that cannot catch a
# removed security guard is not a suite.
#
# It deliberately uses plain exit codes and no test framework, so the mechanism
# it audits cannot also shadow the audit.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PYTHON=${PYTHON:-python3}
PYTHONDONTWRITEBYTECODE=1
export PYTHONDONTWRITEBYTECODE

WORK_DIR=$(mktemp -d)
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT INT TERM

# Reject a Makefile that would silently ignore this guard's own failure. Also
# invoked from check-baseline.sh, so neutering either recipe leaves the other
# able to report the tampering.
"$ROOT_DIR/scripts/check-make-integrity.sh"

SCRATCH="$WORK_DIR/tree"
mkdir -p "$SCRATCH/tests"
cp "$ROOT_DIR/utils.py" "$SCRATCH/utils.py"
cp "$ROOT_DIR/tests/"*.py "$SCRATCH/tests/"

# Written out as a real file rather than an inline heredoc: a heredoc inside a
# command substitution inside an `if` condition is a syntax error in dash, and a
# shell syntax error exits non-zero exactly like a caught mutation would.
MUTATE_PY="$WORK_DIR/mutate.py"
cat >"$MUTATE_PY" <<'PY'
import os
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
old = os.environ["OLD_TEXT"]
new = os.environ["NEW_TEXT"]
source = path.read_text(encoding="utf-8")
hits = source.count(old)
if hits < 1:
    sys.stderr.write("mutation anchor not found: %r\n" % (old,))
    raise SystemExit(1)
path.write_text(source.replace(old, new, 1), encoding="utf-8")
sys.stdout.write("%d\n" % hits)
PY

run_suite() {
  # Plain exit code only. 0 => suite reported success.
  (cd "$SCRATCH" && "$PYTHON" -m unittest discover -s tests -p "test*.py") \
    >"$WORK_DIR/suite.log" 2>&1
}

# A scratch copy that cannot pass clean would make every planted defect look
# "caught" while proving nothing. Establish the green baseline first.
if ! run_suite; then
  printf '%s\n' "Mutation guard baseline failed: the unmutated scratch suite must pass." >&2
  sed -n '$p' "$WORK_DIR/suite.log" >&2
  exit 1
fi

BASELINE_TESTS=$(sed -n 's/^Ran \([0-9]\{1,\}\) test.*/\1/p' "$WORK_DIR/suite.log" | head -1)
if [ -z "${BASELINE_TESTS:-}" ] || [ "$BASELINE_TESTS" -lt 40 ]; then
  printf '%s\n' "Mutation guard baseline must run the full offline suite; saw '${BASELINE_TESTS:-none}' tests." >&2
  exit 1
fi

MUTATIONS_RUN=0

expect_caught() {
  label=$1
  relative_path=$2
  old_text=$3
  new_text=$4
  target="$SCRATCH/$relative_path"

  # Restore the pristine copy before each planted defect.
  case "$relative_path" in
  tests/*) cp "$ROOT_DIR/$relative_path" "$target" ;;
  *) cp "$ROOT_DIR/$relative_path" "$target" ;;
  esac

  # Apply the defect and prove it applied. A mutation that silently fails to
  # apply leaves a clean tree, and a clean tree's exit 0 is indistinguishable
  # from a surviving mutation. Absence of a hit is a broken probe, not a pass.
  hits=$(OLD_TEXT="$old_text" NEW_TEXT="$new_text" "$PYTHON" "$MUTATE_PY" "$target") || {
    printf '%s\n' "Mutation guard probe is invalid: anchor for '$label' no longer exists in $relative_path." >&2
    printf '%s\n' "Update scripts/mutation-guard.sh to plant an equivalent real defect." >&2
    exit 1
  }

  if run_suite; then
    printf '%s\n' "Mutation guard FAILED: the suite still passed with a planted defect ($label)." >&2
    printf '%s\n' "The suite does not observe behaviour it claims to verify -- assertions may be shadowed or missing." >&2
    sed -n '$p' "$WORK_DIR/suite.log" >&2
    exit 1
  fi

  cp "$ROOT_DIR/$relative_path" "$target"
  MUTATIONS_RUN=$((MUTATIONS_RUN + 1))
  printf '%s\n' "  rejected: $label (anchor hits: $hits)"
}

printf '%s\n' "Planting real defects against the offline suite ($BASELINE_TESTS tests)..."

# Each planted defect removes a guard the suite claims to cover. Each must make
# the real suite fail. Bodies are replaced rather than deleted so the mutation
# stays syntactically valid -- a syntax error is caught by the parser, not by
# the assertions, and would look identical from the exit code.
expect_caught "https download guard neutered" "utils.py" \
  "def require_https_url(url):" \
  "def require_https_url(url):
    return None


def _unreachable_require_https_url(url):"

expect_caught "kaggle host allowlist neutered" "utils.py" \
  "def require_allowed_data_file(filename):" \
  "def require_allowed_data_file(filename):
    return None


def _unreachable_require_allowed_data_file(filename):"

expect_caught "explicit port rejection disabled" "utils.py" \
  "if parsed_url.port is not None:" \
  "if False:"

expect_caught "zip payload validation neutered" "utils.py" \
  "def require_valid_zip_file(source):" \
  "def require_valid_zip_file(source):
    return None


def _unreachable_require_valid_zip_file(source):"

expect_caught "cached download size limit disabled" "utils.py" \
  "if os.fstat(handle.fileno()).st_size > max_download_bytes:" \
  "if False:"

expect_caught "download root identity check neutered" "utils.py" \
  "def require_download_root_identity(output_root, root_fd):" \
  "def require_download_root_identity(output_root, root_fd):
    return None


def _unreachable_require_download_root_identity(output_root, root_fd):"

# The six defects above are all detected by tests that assert a raise, so they
# are detected through assertRaises/assertRaisesRegex alone. A shadow that
# neuters only assertEqual/assertFalse/assertTrue -- 119 of this suite's 168
# assertions -- would leave every one of them caught and slip through.
#
# This defect is deliberately non-raising: it silently fails to roll back an
# invocation-owned published file, and is detected only by the state assertions
# (assertEqual/assertFalse) that the raise-based defects never exercise.
# Verified: it survives the suite when those three methods are shadowed.
# Keep at least one defect from each family, or this guard measures half a suite.
expect_caught "published-file rollback silently skipped (non-raising)" "utils.py" \
  "unlink_if_fingerprint_matches(root_fd, filename, published_fingerprint)" \
  "pass"

# Note on the attack this guard exists to stop: a shadowed assertion mechanism
# (assert* methods overridden to return None on the TestCase, leaving every
# pinned test name and every pinned assertion source line byte-identical) is
# caught here by construction rather than by a dedicated probe. If assertions
# cannot fail, the planted defects above cannot be detected, the suite reports
# success, and this guard fails on the first mutation. No pin is required.

if [ "$MUTATIONS_RUN" -lt 7 ]; then
  printf '%s\n' "Mutation guard must plant at least 7 defects; only ran $MUTATIONS_RUN." >&2
  exit 1
fi

printf '%s\n' "Mutation guard: $MUTATIONS_RUN planted defects were all rejected by the offline suite."
