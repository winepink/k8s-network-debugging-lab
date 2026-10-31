# Following one request

The request in this repo is `client -> http://echo/`. It looks simple from inside the pod. In the longer lab I had to look at DNS, Service state, the node, Cilium, and the actual connection before it made sense. The useful distinction is where each observation was made.

| At this point | What I captured in the longer lab | What that observation tells me |
| --- | --- | --- |
| Name resolution | CoreDNS state, pod DNS checks, and failed `curl` output when CoreDNS was scaled down (pages 6–14) | Whether the client got an address for the Service before trying TCP. A DNS failure says nothing about whether an already known Service IP is reachable. |
| Service selection | Three echo backends, EndpointSlices, kube-proxy iptables rules, and repeated requests (pages 20–27) | The Service has eligible endpoints. The backend selected for a connection still has to be checked from the response or packet state. |
| Pod and node path | Pod IPs and node placement, `tcpdump`, Cilium status, and node interfaces (pages 6–12) | Which interface saw the packet. A capture on one interface cannot stand in for the entire path. |
| Connection state | Host conntrack and Cilium maps (pages 32–40) | Why traffic belonging to an existing connection can keep its earlier translation. These are different views, so I would not expect their rows to match one for one. |
| Policy | Cilium policy and Hubble `DROPPED` / `EGRESS DENIED` events (pages 32–40) | A drop verdict attached to the client and echo endpoints is stronger evidence of policy enforcement than a `curl` timeout by itself. |

## In the smaller kind setup

The local cluster has one control plane and two workers. Its [kind configuration](../cluster/kind.yaml) disables the default CNI and explicitly sets kube-proxy to iptables mode. [Setup](../scripts/up.sh) installs Cilium with VXLAN tunneling and kube-proxy replacement disabled. That choice keeps the Service translation and the pod network separate enough to inspect.

`make path-state` prints the client and echo pod placement, the Service and EndpointSlices, the two networking DaemonSets, and the Cilium Helm values used for this cluster. The node column matters. A same-node pod path will not show an inter-node VXLAN hop. An echo replica on another node gives a candidate for that path, but the request must actually select that replica before a capture can be tied to it.

The sequence I use when looking at a particular request is:

1. Record the client pod, node, Service IP, and ready endpoint IPs.
2. Make one request and record the echo pod name in the response.
3. Match that name to its pod IP and node.
4. Inspect Hubble for the source, destination, and verdict. Use a packet capture at a named interface only when I need packet headers or a precise boundary.
5. Compare the selected backend with Service and connection state. Do not infer a new selection for every HTTP request when a TCP connection was reused.

The `tcpdump` and conntrack material in the longer lab is historical. I do not have the raw capture file in this repository, so there is no invented packet transcript here. The table records what was inspected and the limits of each view. The [failure cases](incidents.md) contain the observed DNS and policy outcomes.

## Where the VPC and fabric questions fit

The kind nodes are containers on one Docker host. A VXLAN packet between those containers is enough to study encapsulation and its MTU cost. It does not recreate a cloud VPC route table, an underlay BGP design, or a leaf-spine fabric. Those subjects came up because the same question continues below Kubernetes: once a node emits an outer packet, how does the network carry it to the other node? This repo stops at the node and Docker network boundary.

## References

- [Kubernetes Service virtual IPs and iptables proxy mode](https://kubernetes.io/docs/reference/networking/virtual-ips/)
- [Cilium encapsulation routing](https://docs.cilium.io/en/stable/network/concepts/routing/)
- [Cilium troubleshooting and datapath state](https://docs.cilium.io/en/stable/operations/troubleshooting/)
- [Hubble flow inspection](https://docs.cilium.io/en/stable/observability/hubble/hubble-cli/)
