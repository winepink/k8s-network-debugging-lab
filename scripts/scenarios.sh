#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/lib.sh"

usage() {
  printf 'usage: %s {dns-down|dns-up|policy-on|policy-off|request|service-routing}\n' "$0" >&2
  exit 2
}

(( $# == 1 )) || usage
require_cluster

lab_label=$(k get namespace "$NAMESPACE" -o 'jsonpath={.metadata.labels.app\.kubernetes\.io/part-of}')
[[ "$lab_label" == "$NAMESPACE" ]] || die "namespace '$NAMESPACE' is not the lab namespace"

dns_snapshot="coredns-replicas-before-fault"
policy_file="$ROOT_DIR/workloads/deny-client-to-echo.yaml"

request() {
  k -n "$NAMESPACE" exec deployment/client -- curl -fsS --max-time 5 http://echo/
}

case "$1" in
  dns-down)
    if k -n "$NAMESPACE" get configmap "$dns_snapshot" >/dev/null 2>&1; then
      die "CoreDNS replica snapshot already exists. Restore DNS before injecting it again."
    fi
    replicas=$(k -n kube-system get deployment/coredns -o 'jsonpath={.spec.replicas}')
    [[ "$replicas" =~ ^[1-9][0-9]*$ ]] || die "CoreDNS has no running replica count to save"
    k -n "$NAMESPACE" create configmap "$dns_snapshot" --from-literal="replicas=$replicas"
    if ! k -n kube-system scale deployment/coredns --replicas=0 --current-replicas="$replicas"; then
      k -n "$NAMESPACE" delete configmap "$dns_snapshot"
      die "CoreDNS scale failed; the saved replica count was removed"
    fi
    k -n kube-system rollout status deployment/coredns --timeout=90s
    printf 'CoreDNS is at zero replicas. Original count: %s\n' "$replicas"
    ;;
  dns-up)
    replicas=$(k -n "$NAMESPACE" get configmap "$dns_snapshot" -o 'jsonpath={.data.replicas}') ||
      die "no saved CoreDNS replica count found"
    [[ "$replicas" =~ ^[1-9][0-9]*$ ]] || die "saved CoreDNS replica count is invalid"
    k -n kube-system scale deployment/coredns --replicas="$replicas" --current-replicas=0
    k -n kube-system rollout status deployment/coredns --timeout=3m
    k -n "$NAMESPACE" delete configmap "$dns_snapshot"
    printf 'CoreDNS restored to %s replicas.\n' "$replicas"
    ;;
  policy-on)
    k apply -f "$policy_file"
    printf 'Client-to-echo deny policy applied in %s.\n' "$NAMESPACE"
    ;;
  policy-off)
    k delete -f "$policy_file" --ignore-not-found
    printf 'Client-to-echo deny policy removed from %s.\n' "$NAMESPACE"
    ;;
  request)
    request
    ;;
  service-routing)
    k -n "$NAMESPACE" get pods -l app=echo -o wide
    k -n "$NAMESPACE" get service echo
    k -n "$NAMESPACE" get endpointslices -l kubernetes.io/service-name=echo -o wide
    printf '\nSeparate curl processes, one TCP connection per request:\n'
    for _ in 1 2 3 4 5 6; do
      request
    done
    printf '\nOne curl process, three transfers to the same Service:\n'
    k -n "$NAMESPACE" exec deployment/client -- curl -fsS --http1.1 \
      -w 'new_connections=%{num_connects}\n' \
      http://echo/ http://echo/ http://echo/
    ;;
  *) usage ;;
esac
