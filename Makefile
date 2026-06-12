.PHONY: build lint test verify check

PYTHON ?= python3

lint:
	./scripts/check-baseline.sh
	$(PYTHON) -m ruff format --check .
	$(PYTHON) -m ruff check .

test:
	$(PYTHON) -m unittest discover -s tests -p "test*.py"

build:
	$(PYTHON) -m py_compile utils.py tests/testutils.py

verify: lint test build

check: verify
	$(PYTHON) -m pip_audit -r requirements.txt -r requirements-dev.txt
