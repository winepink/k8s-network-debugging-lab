.PHONY: preflight up baseline down dns-down dns-up policy-on policy-off request service-routing

preflight:
	bash scripts/preflight.sh

up:
	bash scripts/up.sh

baseline:
	bash scripts/baseline.sh

down:
	bash scripts/down.sh

dns-down:
	bash scripts/scenarios.sh dns-down

dns-up:
	bash scripts/scenarios.sh dns-up

policy-on:
	bash scripts/scenarios.sh policy-on

policy-off:
	bash scripts/scenarios.sh policy-off

request:
	bash scripts/scenarios.sh request

service-routing:
	bash scripts/scenarios.sh service-routing
