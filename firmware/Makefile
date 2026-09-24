# Firmware tasks. PORT defaults to the first USB serial device mpremote finds.
VENV ?= .venv
BIN := $(VENV)/bin
PORT ?= auto
MP := $(BIN)/mpremote connect $(PORT)

.PHONY: venv test lint deps deploy run repl reset

venv:
	python3 -m venv $(VENV) && $(BIN)/pip install -r requirements-dev.txt

test:
	$(BIN)/pytest

lint:
	$(BIN)/ruff check src tests && $(BIN)/ruff format --check src tests

# One-time per board: install aioble from micropython-lib onto the device.
deps:
	$(MP) mip install aioble

# Copy the source tree to the board's filesystem and soft-reset.
deploy:
	$(MP) fs cp -r src/tnt : + fs cp src/config.py src/main.py : + reset

# Run main.py from the host without copying it (fast iteration, output in terminal).
run:
	$(MP) fs cp -r src/tnt : + fs cp src/config.py : + run src/main.py

repl:
	$(MP) repl

reset:
	$(MP) reset
