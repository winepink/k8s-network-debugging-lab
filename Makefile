.PHONY: preflight up baseline down

preflight:
	bash scripts/preflight.sh

up:
	bash scripts/up.sh

baseline:
	bash scripts/baseline.sh

down:
	bash scripts/down.sh
