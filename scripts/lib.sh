#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="netpath-lab"
CONTEXT_NAME="kind-${CLUSTER_NAME}"
NAMESPACE="netpath-lab"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

cluster_exists() {
  kind get clusters | grep -Fxq "$CLUSTER_NAME"
}

require_cluster() {
  cluster_exists || die "kind cluster '$CLUSTER_NAME' does not exist. Run make up."
  kubectl config get-contexts -o name | grep -Fxq "$CONTEXT_NAME" ||
    die "kubectl context '$CONTEXT_NAME' is missing."
}

k() {
  kubectl --context "$CONTEXT_NAME" "$@"
}
