# Delivery roadmap

This project is being built in five parts so each stage has a clear purpose. A checked box means the work is present in the repository, not that an older lab run was repeated.

## 1/5 — Foundation and evidence audit

- [x] Define the problem and the audience.
- [x] Map the strongest recorded experiments to incident writeups.
- [x] Mark observed output separately from explanations and unverified claims.
- [x] Choose a small, isolated architecture for the replayable lab.
- [x] Record scope and limitations before adding implementation.

## 2/5 — Local baseline

- [ ] Add a kind cluster configuration with a deliberately chosen CNI and Service path.
- [ ] Add a small echo workload, a client, and an explicit namespace.
- [ ] Add preflight, setup, baseline, and teardown commands with context checks.
- [ ] Document what each command is expected to change.

## 3/5 — Failure cases

- [ ] Add reversible DNS and Cilium policy failures.
- [ ] Add an incident guide for each failure: symptom, hypothesis, checks, evidence, fix.
- [ ] Add Service routing inspection and distinguish new connections from reused ones.
- [ ] Keep fault injection scoped to the lab cluster.

## 4/5 — Deeper network analysis

- [ ] Curate the recorded packet, flow, and conntrack evidence.
- [ ] Add focused notes on VXLAN, MTU, and cross-cluster TLS where the original record supports them.
- [ ] Review technical claims against current upstream documentation and the actual lab configuration.
- [ ] Keep conceptual VPC, mesh, and datacenter material tied to an observed question.

## 5/5 — Verification and publication polish

- [ ] Check manifests and scripts with the available static tools.
- [ ] Run the local scenarios if an environment is available. Report what was and was not exercised.
- [ ] Review the README as a first-time reader and remove stale or unsupported statements.
- [ ] Scan the diff for credentials, internal details, and unneeded generated files.
- [ ] Check every link and command shown to a first-time reader.

The original experiments were already run and recorded. Repeating the entire 90-page lab is not a requirement for finishing this repository. New automation will still be checked as far as the available environment allows, and its verification status will be stated plainly.
