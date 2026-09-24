# Monorepo entry points. Each subproject also has its own Makefile.
.PHONY: test test-firmware test-ios

test: test-firmware test-ios

test-firmware:
	cd firmware && python3 -m pytest -q

test-ios:
	$(MAKE) -C ios test
