.PHONY: build lint test verify check

PYTHON ?= python3
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

lint:
	PYTHON="$(PYTHON)" "$(ROOT)/scripts/check-baseline.sh"
	$(PYTHON) -m ruff format --check "$(ROOT)"
	$(PYTHON) -m ruff check "$(ROOT)"

test:
	cd "$(ROOT)" && $(PYTHON) -m unittest discover -s tests -p "test*.py"

build:
	$(PYTHON) -m py_compile "$(ROOT)/utils.py" "$(ROOT)/tests/testutils.py"

verify: lint test build

check: verify
	$(PYTHON) -m pip_audit -r "$(ROOT)/requirements.txt" -r "$(ROOT)/requirements-dev.txt"
