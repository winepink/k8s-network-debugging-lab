.PHONY: preflight up baseline down

preflight:
	./scripts/preflight.sh

up:
	./scripts/up.sh

baseline:
	./scripts/baseline.sh

down:
	./scripts/down.sh
