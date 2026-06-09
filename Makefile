.PHONY: build lint test verify check

PYTHON ?= python3

lint:
	./scripts/check-baseline.sh

test:
	$(PYTHON) -m unittest discover -s tests -p "test*.py"

build:
	$(PYTHON) -m py_compile utils.py tests/testutils.py

verify: lint test build

check: verify
