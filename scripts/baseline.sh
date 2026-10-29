#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_cluster

printf 'Context: %s\nNamespace: %s\n\n' "$CONTEXT_NAME" "$NAMESPACE"
k -n "$NAMESPACE" get pods -o wide
printf '\nService and backends:\n'
k -n "$NAMESPACE" get service echo
k -n "$NAMESPACE" get endpointslices -l kubernetes.io/service-name=echo
printf '\nRequest from the client pod:\n'
k -n "$NAMESPACE" exec deployment/client -- curl -fsS --max-time 5 http://echo/
