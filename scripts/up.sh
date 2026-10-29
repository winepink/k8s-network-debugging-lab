#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/lib.sh"

bash "$ROOT_DIR/scripts/preflight.sh"

if ! cluster_exists; then
  kind create cluster --name "$CLUSTER_NAME" --config "$ROOT_DIR/cluster/kind.yaml"
fi
require_cluster

if k -n kube-system get daemonset kindnet >/dev/null 2>&1; then
  die "'$CLUSTER_NAME' has kindnet installed. It is not the Cilium lab cluster."
fi

if ! helm status cilium -n kube-system --kube-context "$CONTEXT_NAME" >/dev/null 2>&1; then
  helm install cilium oci://quay.io/cilium/charts/cilium \
    --version 1.20.4 \
    --namespace kube-system \
    --kube-context "$CONTEXT_NAME" \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=false \
    --set routingMode=tunnel \
    --set tunnelProtocol=vxlan \
    --set hubble.enabled=true \
    --set hubble.relay.enabled=true \
    --set operator.replicas=1 \
    --wait --timeout 5m
fi

k wait nodes --all --for=condition=Ready --timeout=5m
k -n kube-system rollout status daemonset/cilium --timeout=5m
k -n kube-system rollout status deployment/cilium-operator --timeout=5m
k apply -f "$ROOT_DIR/workloads/namespace.yaml"
k apply -f "$ROOT_DIR/workloads/echo.yaml"
k apply -f "$ROOT_DIR/workloads/client.yaml"
k -n "$NAMESPACE" rollout status deployment/echo --timeout=3m
k -n "$NAMESPACE" rollout status deployment/client --timeout=3m

printf '\nBaseline is deployed in context %s and namespace %s.\n' "$CONTEXT_NAME" "$NAMESPACE"
printf 'Run make baseline to inspect the Service and send a request.\n'
