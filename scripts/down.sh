#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/lib.sh"

command -v kind >/dev/null 2>&1 || die "missing 'kind' in PATH"
if ! cluster_exists; then
  printf 'Cluster %s is already absent.\n' "$CLUSTER_NAME"
  exit 0
fi

printf 'Deleting only kind cluster: %s\n' "$CLUSTER_NAME"
kind delete cluster --name "$CLUSTER_NAME"
