# Three failures in one network path

The same client and echo Service make the failures easier to compare. The client runs in `netpath-lab`, the Service has three echo backends, Cilium handles pod networking, and kube-proxy handles Service translation in iptables mode. The commands below use only the named `kind-netpath-lab` context.

## DNS disappears

In my original run, I scaled CoreDNS down and captured the client failing to resolve a Service name. That failure happens before a TCP connection to the echo Service can start. It is different from a connection that resolves correctly and then times out.

```sh
make request
make dns-down
kubectl --context kind-netpath-lab -n kube-system get deployment coredns
make request
make dns-up
make request
```

`dns-down` saves the previous CoreDNS replica count in a ConfigMap in the lab namespace, then scales CoreDNS to zero. `dns-up` restores that count and removes the snapshot. Both commands refuse to act without the named kind cluster and the lab namespace label.

For a more specific check while DNS is down, an address-pinned request can bypass name resolution without bypassing the Service:

```sh
service_ip=$(kubectl --context kind-netpath-lab -n netpath-lab get service echo -o jsonpath='{.spec.clusterIP}')
kubectl --context kind-netpath-lab -n netpath-lab exec deployment/client -- \
  curl -fsS --max-time 5 --resolve "echo:80:$service_ip" http://echo/
```

If the pinned request succeeds while `make request` cannot resolve `echo`, the Service and pod path are still reachable. The original lab captured the resolution failure. The pinned comparison is part of this smaller replay.

## Echo traffic is denied

The policy in [`deny-client-to-echo.yaml`](../workloads/deny-client-to-echo.yaml) selects the client pod, allows other egress, and explicitly denies traffic to pods labeled `app=echo`. DNS stays available, which keeps this case separate from the CoreDNS outage. In the original policy run, Hubble showed `DROPPED` and `EGRESS DENIED` events.

```sh
make request
make policy-on
kubectl --context kind-netpath-lab -n netpath-lab get ciliumnetworkpolicy deny-client-to-echo
make request
make policy-off
make request
```

The denied request should resolve `echo` and then fail to connect. A recent Hubble drop verdict can locate the policy boundary if the Hubble CLI is available:

```sh
hubble observe -P --verdict DROPPED
```

The verdict needs to be matched to the client and echo endpoints. A timeout alone does not prove which policy, if any, dropped the packet. `policy-off` deletes only this policy from the lab namespace.

## Three backends are not a round robin

The original Service run used three backends and compared EndpointSlices, iptables rules, Cilium maps, conntrack, and Hubble flows. The number of ready endpoints did not imply that successive HTTP requests would visit each backend in order.

```sh
make service-routing
```

The first group runs a fresh `curl` process for each request. The second group asks one `curl` process to make three transfers to the same Service. The echo body identifies the pod that answered. Curl's `new_connections` value is `1` for a new connection and `0` when it reused one. If the second group reuses a TCP connection, all requests on that connection keep the backend selected for it. If the server closes the connection, Curl will open another and the output will show that. The EndpointSlice list shows available backends, not a promise about the order of selections.

## References

- [Cilium deny policies](https://docs.cilium.io/en/stable/security/policy/deny/)
- [Cilium layer 3 policy examples](https://docs.cilium.io/en/stable/security/policy/layer3/)
- [Hubble CLI flow inspection](https://docs.cilium.io/en/stable/observability/hubble/hubble-cli/)
- [Kubernetes Deployment scaling](https://kubernetes.io/docs/tasks/run-application/scale-deployment/)
