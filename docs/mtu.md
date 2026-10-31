# MTU at the overlay boundary

The MTU question in my lab started at the boundary between a pod packet and the outer packet sent between nodes. Cilium is configured for VXLAN here. The outer Ethernet, IP, UDP, and VXLAN headers take space, so the pod-facing MTU must be smaller than the underlay path can carry. Cilium's routing documentation gives 50 bytes of VXLAN overhead. With a 1500-byte underlay MTU, that leaves 1450 bytes for the inner packet. That is a sizing example, not a measurement of this machine.

The original record includes MTU and fragmentation checks on pages 52–55. I cannot tell from the evidence map alone which packet size crossed which interface, so I am not turning those pages into a claimed threshold or throughput result.

For the local setup, the first check is the configured MTU at each visible boundary:

```sh
kubectl --context kind-netpath-lab -n netpath-lab exec deployment/client -- \
  cat /sys/class/net/eth0/mtu
docker exec netpath-lab-worker ip -o link show
```

The first value is the pod interface. The second lists interfaces inside one kind node, including the node's path toward the Docker network. If I later capture a large packet, I need its ingress and egress interfaces, DF flag, and whether segmentation offload affected the capture point before calling it fragmentation. A successful small `curl` does not exercise the MTU boundary.

An MTU failure can look like a selective timeout. Small requests work, then a larger response stalls when packets cannot cross a lower-MTU hop and path MTU discovery cannot complete. I would check that hypothesis with packet sizes and ICMP behavior, then compare the pod-facing value with the actual underlay path. I would not tune Cilium's MTU from a timeout alone.

See [the packet path](packet-path.md) for the interfaces and connection state that frame this check.

## Reference

- [Cilium encapsulation and MTU overhead](https://docs.cilium.io/en/stable/network/concepts/routing/)
