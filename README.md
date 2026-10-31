# Kubernetes network debugging lab

I put this lab together to get past the point where Kubernetes networking feels like a collection of names: CNI, Services, DNS, policy, conntrack, overlay, ingress. When a request fails, those names are only useful if I can locate the packet, see where its path changed, and explain why.

The work began with a multi-node kind cluster and Cilium. I followed traffic from a pod through DNS resolution, Service translation, and the node network. Then I broke individual parts of that path and compared what `curl`, `tcpdump`, Cilium, and Hubble told me. The original lab also went further into cross-cluster calls, TLS, MTU, retries, and the connection between Kubernetes networking and the networks underneath it.

This repository is my organized version of those investigations. It uses generic workloads so the packet paths stay easy to follow.

## Local baseline

This setup uses Docker, kind, kubectl, and Helm. The cluster is named `netpath-lab`, and every Kubernetes command in the scripts targets `kind-netpath-lab` explicitly.

```sh
make preflight
make up
make baseline
make down
```

`preflight` checks the required tools, Docker, and any existing lab cluster. `up` creates the named kind cluster if needed, installs Cilium, and deploys the client and echo workloads. `baseline` lists the pods, Service, and EndpointSlices, then sends one request from the client. `down` deletes only the named kind cluster.

The cluster uses Cilium for pod networking and keeps kube-proxy in iptables mode for Service handling. There are two worker nodes so the later packet-path cases can include traffic between nodes.

## Failure cases

I kept the local failures small enough to compare the same request at different layers. The [incident notes](docs/incidents.md) cover CoreDNS disappearing, Cilium denying client-to-echo traffic, and three Service backends that do not behave like a round robin. The corresponding commands are `make dns-down`, `make dns-up`, `make policy-on`, `make policy-off`, and `make service-routing`.

The [packet-path notes](docs/packet-path.md) connect the DNS, Service, node, flow, and conntrack observations. `make path-state` prints the live topology and Cilium settings for the local cluster. The [MTU note](docs/mtu.md) follows the VXLAN boundary, and the [cross-cluster TLS note](docs/cross-cluster-tls.md) separates reachability from certificate identity.

## References

- [kind configuration](https://kind.sigs.k8s.io/docs/user/configuration)
- [Cilium installation on kind](https://docs.cilium.io/en/stable/installation/kind/)
- [Cilium policy enforcement](https://docs.cilium.io/en/stable/security/policy/intro/)
- [Hubble setup](https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/)
