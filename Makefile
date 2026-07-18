.PHONY: build lint test mutation-guard verify check

PYTHON ?= python3
override ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

lint:
	PYTHON="$(PYTHON)" "$(ROOT)/scripts/check-baseline.sh"
	$(PYTHON) -m ruff format --check "$(ROOT)"
	$(PYTHON) -m ruff check "$(ROOT)"

test:
	cd "$(ROOT)" && $(PYTHON) -m unittest discover -s tests -p "test*.py"

build:
	$(PYTHON) -m py_compile "$(ROOT)/utils.py" "$(ROOT)/tests/testutils.py"

# Double-colon: a single-colon rule's recipe can be silently replaced by a later
# rule for the same target (make keeps the last recipe and only warns). A `::`
# rule cannot be overridden, only added to, so the behavioural guard cannot be
# neutered by redefining it with an empty recipe.
mutation-guard::
	PYTHON="$(PYTHON)" "$(ROOT)/scripts/mutation-guard.sh"

verify: lint test build mutation-guard

check: verify
	$(PYTHON) -m pip_audit -r "$(ROOT)/requirements.txt" -r "$(ROOT)/requirements-dev.txt"
