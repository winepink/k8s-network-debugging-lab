# Kubernetes network debugging lab

I put this lab together to get past the point where Kubernetes networking feels like a collection of names: CNI, Services, DNS, policy, conntrack, overlay, ingress. When a request fails, those names are only useful if I can locate the packet, see where its path changed, and explain why.

The work began with a multi-node kind cluster and Cilium. I followed traffic from a pod through DNS resolution, Service translation, and the node network. Then I broke individual parts of that path and compared what `curl`, `tcpdump`, Cilium, and Hubble told me. The original lab also went further into cross-cluster calls, TLS, MTU, retries, and the connection between Kubernetes networking and the networks underneath it.

This repository is my organized version of those investigations. It uses generic workloads so the packet paths stay easy to follow.

## What is here today

This is **part 1 of 5**. I have mapped the recorded experiments to a smaller set of incidents and defined the setup that later parts will make runnable. The [evidence map](docs/evidence-map.md) distinguishes terminal output captured during the original lab from explanations and proposed exercises. The [design](docs/design.md) explains why the repo starts with one kind cluster and a few failure cases.

The new repository has not been run end to end yet. This part is the foundation. Scripts, manifests, tests, and replayed examples belong to later parts.

## The questions I want this repo to answer

1. A name stops resolving. Is CoreDNS down, is the Service wrong, or did policy drop the DNS query?
2. A Service has three healthy backends. Why can several requests still land on the same pod?
3. A connection times out. Did the SYN leave the client, reach a backend, or disappear at a policy boundary?
4. A cross-cluster HTTPS call works with `-k` but fails normally. What does that say about routing, trust, and hostname validation?

Those are different failures, even though the first thing a developer often sees is just “the request failed.” I want each case to show the command that narrowed the possibilities, the evidence it produced, and the next question that evidence raised.

## How the investigation is organized

| Incident | First symptom | Evidence to inspect | What it teaches |
| --- | --- | --- | --- |
| DNS outage | `curl` cannot resolve a Service name | Pod resolver, CoreDNS Deployment and Service, DNS packets | Separate name resolution from TCP reachability |
| Policy denial | DNS or Service traffic times out | Cilium policy, endpoint identity, Hubble drop verdict | Identify a deliberate drop instead of treating it as a generic outage |
| Service routing | Requests reach different backends, but not in neat rotation | EndpointSlice, connection reuse, Cilium service and connection maps | Separate backend selection from per-connection behavior |
| Cross-cluster TLS | TCP connects, then certificate validation fails | Address, SNI/hostname, certificate chain | Separate a transport path from application-layer trust |

The first three will form the runnable core. Cross-cluster TLS will remain a documented extension until the local core is solid.

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the five delivery parts and their completion criteria.

## References

- [kind configuration](https://kind.sigs.k8s.io/docs/user/configuration)
- [Cilium installation on kind](https://docs.cilium.io/en/stable/installation/kind/)
- [Cilium policy enforcement](https://docs.cilium.io/en/stable/security/policy/intro/)
- [Hubble setup](https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/)
