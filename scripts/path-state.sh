#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/lib.sh"

require_cluster
lab_label=$(k get namespace "$NAMESPACE" -o 'jsonpath={.metadata.labels.app\.kubernetes\.io/part-of}')
[[ "$lab_label" == "$NAMESPACE" ]] || die "namespace '$NAMESPACE' is not the lab namespace"

printf 'Context: %s\nNamespace: %s\n\n' "$CONTEXT_NAME" "$NAMESPACE"
printf 'Client and echo placement:\n'
k -n "$NAMESPACE" get pods -l 'app in (client,echo)' -o wide
printf '\nService IP and endpoints:\n'
k -n "$NAMESPACE" get service echo -o wide
k -n "$NAMESPACE" get endpointslices -l kubernetes.io/service-name=echo -o wide
printf '\nNetworking agents:\n'
k -n kube-system get daemonset cilium kube-proxy
printf '\nCilium install values:\n'
helm get values cilium -n kube-system --kube-context "$CONTEXT_NAME" -o yaml
