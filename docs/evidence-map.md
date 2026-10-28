# Evidence map

The source is my 90-page Kubernetes networking lab record. This map is here so future writeups can stay close to what I actually did. Page numbers refer to that private record. The PDF itself is not part of this public repository.

## Captured experiments worth carrying forward

| Pages | What I did or captured | What this repo can support |
| --- | --- | --- |
| 2–5 | Created a multi-node kind cluster with the default CNI disabled, installed Cilium and Hubble, and inspected cluster state. | Rebuild a small local baseline. Verify the exact Cilium and kube-proxy mode rather than inferring it from an installation command. |
| 6–12 | Traced DNS and pod traffic with `tcpdump`, Cilium status, and node interfaces. Explored VXLAN and endpoint identities. | Explain where a packet is visible at the pod, node, and overlay layers. |
| 13–14 | Scaled CoreDNS down and recorded failed name resolution and `curl` output. | DNS outage incident: distinguish failed resolution from failed TCP connection. |
| 15–18 | Captured external egress and NAT behavior. | Short packet-path note, with host and Docker bridge behavior called out as lab-specific. |
| 20–27 | Ran a three-backend Service, inspected EndpointSlices, iptables rules, Cilium service and BPF maps, and Hubble flows. | Service-routing incident: explain backend selection and connection reuse with observed output. |
| 32–40 | Compared host conntrack and Cilium maps. Applied policies and observed Hubble `DROPPED` and `EGRESS DENIED` events. | Policy incident: identify where the drop happened and how to restore access. |
| 43–51 | Explored Service types, NodePort, ingress, and host-based routing. | Background material only where it helps explain a case. |
| 52–55 | Tried MTU and fragmentation checks and explored conntrack pressure. | Advanced diagnostic note, with care around any result that depends on host networking or load. |
| 56–64 | Used two kind clusters, cross-cluster NodePort, TLS, timeout, and DNS checks. | An extension focused on the difference between a reachable address and a valid service identity. |
| 66–69 | Installed cert-manager and tried certificate-backed HTTPS in the lab. | TLS extension, after checking the exact certificate and hostname behavior. |
| 81–82 | Installed Istio and noted sidecar injection and the control/data plane split. | Context for service mesh, outside the core setup. |

## Notes that need careful treatment

- The opening outline names applications such as an ingest API, replicator, queue, and storage service. The captured pages mainly use echo, curl, and nginx workloads. I will not claim those larger applications were implemented in this lab.
- The record contains both kube-proxy iptables output and Cilium BPF map output. They show useful observations, but they do not by themselves prove every statement about which component handled every packet in every run. The repo will record the actual configuration before making that comparison.
- A few notes summarize performance as “linear iptables versus O(1) eBPF.” That is too broad to present as a measured result. This repo will discuss lookup mechanisms and operational tradeoffs without invented benchmarks.
- The later VPC, service mesh, Anthos, leaf-spine, BGP, and ECMP sections include conceptual explanations. They are useful context, but they are not evidence that this local kind lab implemented a cloud VPC or a physical fabric.
- Terminal output from the original lab is historical evidence. Commands added to this repository are new implementation and will carry their own verification record.

## Curation rule

Each incident writeup should answer four questions: **What failed? What did I check? What did I actually see? What changed my diagnosis?** If a claim does not have captured output, a reproducible check, or a reliable upstream source behind it, it should be labeled as an explanation or left out.
