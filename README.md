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

## The questions I want this repo to answer

1. A name stops resolving. Is CoreDNS down, is the Service wrong, or did policy drop the DNS query?
2. A Service has three healthy backends. Why can several requests still land on the same pod?
3. A connection times out. Did the SYN leave the client, reach a backend, or disappear at a policy boundary?
4. A cross-cluster HTTPS call works with `-k` but fails normally. What does that say about routing, trust, and hostname validation?

Those are different failures, even though the first thing a developer often sees is just “the request failed.” I want each case to show the command that narrowed the possibilities, the evidence it produced, and the next question that evidence raised.

## How the investigation is organized

| Incident | First symptom | Evidence to inspect | Question |
| --- | --- | --- | --- |
| DNS outage | `curl` cannot resolve a Service name | Pod resolver, CoreDNS Deployment and Service, DNS packets | Did resolution fail before TCP began? |
| Policy denial | DNS or Service traffic times out | Cilium policy, endpoint identity, Hubble drop verdict | Where was traffic dropped? |
| Service routing | Requests reach different backends, but not in neat rotation | EndpointSlice, connection reuse, Cilium service and connection maps | When was a backend selected? |
| Cross-cluster TLS | TCP connects, then certificate validation fails | Address, SNI/hostname, certificate chain | Did transport work while certificate validation failed? |

The first three will form the runnable core. Cross-cluster TLS will remain a documented extension until the local core is solid.

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the five delivery parts and their completion criteria.

## References

- [kind configuration](https://kind.sigs.k8s.io/docs/user/configuration)
- [Cilium installation on kind](https://docs.cilium.io/en/stable/installation/kind/)
- [Cilium policy enforcement](https://docs.cilium.io/en/stable/security/policy/intro/)
- [Hubble setup](https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/)
