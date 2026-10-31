# A reachable address is not a valid TLS identity

Pages 56–69 of the longer lab move between two kind clusters, a NodePort path, DNS, timeouts, TLS, and a certificate-backed HTTPS attempt. The question that stayed with me was why connecting to an address and trusting the service at that address are separate checks.

A NodePort can make a service reachable through a node address and port. That establishes a route and a listener. TLS adds two more requirements: the client must trust the certificate chain, and the certificate must name the host in the URL. A direct request to an IP can therefore reach the server and still fail certificate verification when the certificate is for a DNS name. Replacing the hostname with an IP also changes the name the client verifies.

For a controlled test, `curl --resolve` pins a chosen address while keeping the URL hostname. The URL hostname remains the one used for TLS name verification. For example, with a server that has a certificate for `echo.lab.test` and a CA file that trusts its issuer:

```sh
curl --cacert ./lab-ca.pem \
  --resolve echo.lab.test:443:127.0.0.1 \
  https://echo.lab.test/
```

That command is a pattern, not a command for the current cluster. This repo does not deploy that certificate or expose port 443. It also does not install Cilium Cluster Mesh. The original two-cluster work was a separate NodePort and TLS exercise, so I am not treating it as proof of shared pod routing or cross-cluster Service discovery.

The useful failure split is:

| Result | What it narrows down |
| --- | --- |
| DNS cannot find the name | The client has not reached the address selection step. |
| TCP connection times out or is refused | Addressing, routing, listener, or filtering is still in question. |
| TLS reports an untrusted issuer | The route may work, but the client cannot build trust to the certificate. |
| TLS reports a hostname mismatch | The certificate does not identify the host requested in the URL. |
| HTTPS succeeds | The route, listener, trust chain, and name check all passed for that request. |

Disabling verification would hide the distinction I was trying to investigate. The trust root and the name must both be checked. The certificate details from the old run are not in this repository, so I am leaving its exact success and failure output out.

The service mesh notes later in the original lab are related to service identity, but they are not part of this NodePort test. Installing a sidecar is not evidence that this request used mesh mTLS.

## References

- [kind port mappings and NodePort](https://kind.sigs.k8s.io/docs/user/configuration/)
- [curl certificate verification and `--resolve`](https://curl.se/docs/faq.html)
- [curl hostname verification](https://curl.se/libcurl/c/CURLOPT_SSL_VERIFYHOST.html)
