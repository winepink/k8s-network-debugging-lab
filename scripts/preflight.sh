#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/lib.sh"

for tool in docker kind kubectl helm; do
  command -v "$tool" >/dev/null 2>&1 || die "missing '$tool' in PATH"
done

docker info >/dev/null 2>&1 || die "Docker is installed but the daemon is unavailable. Start Docker and retry."

if cluster_exists; then
  require_cluster
  k cluster-info >/dev/null 2>&1 || die "cannot reach '$CONTEXT_NAME'. Check the kind cluster and kubeconfig."
  printf 'Using existing kind cluster: %s\n' "$CLUSTER_NAME"
else
  printf 'Will create kind cluster: %s\n' "$CLUSTER_NAME"
fi

printf 'Kubernetes context for lab commands: %s\n' "$CONTEXT_NAME"
