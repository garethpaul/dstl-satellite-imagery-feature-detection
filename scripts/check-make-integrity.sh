#!/usr/bin/env sh
# Reject Makefile recipes that silently swallow verification failures.
#
# The Makefile recipe pins in check-baseline.sh are substring greps, so they are
# satisfied just as happily by an *appended* `|| true` as by the pinned text
# alone, and by a prefixed `-` (make's error-ignore marker) as well. Either one
# turns a failing gate into exit 0 while every pinned substring stays present:
# `make lint` was verified to exit 0 with the whole baseline gate neutered and a
# real defect planted in utils.py.
#
# This reads the Makefile *text* deliberately. `make --dry-run` strips `-` and
# `@` from recipe lines, so interrogating make itself is blind to this.
#
# It is invoked from both check-baseline.sh and mutation-guard.sh so that
# neutering either one of those two make recipes still leaves the other able to
# report the tampering. Neutering both is still possible, but no checker running
# under the same make invocation can defend against that; it is a conspicuous
# multi-line diff rather than a single silent token.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MAKEFILE="$ROOT_DIR/Makefile"

# A literal tab. grep -E does NOT interpret \t as a tab -- it matches a literal
# 't' -- so building the character explicitly is required for these patterns to
# mean what they say.
TAB=$(printf '\t')

if grep -nE "^${TAB}-" "$MAKEFILE" >&2; then
  printf '%s\n' "Makefile recipe uses make's error-ignore prefix '-': the above verification failures would be silently ignored." >&2
  exit 1
fi

if grep -nE "^${TAB}.*\|\|[[:space:]]*(true|:)[[:space:]]*$" "$MAKEFILE" >&2; then
  printf '%s\n' "Makefile recipe swallows failures with '|| true': the above verification failures would be silently ignored." >&2
  exit 1
fi
