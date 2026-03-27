# 2026-03-26 – k3s: Pods Failing on Proxmox Node (Kernel / Runtime Issue)

## Context

k3s multi-node cluster:

- Control plane: opti1 (Debian + Proxmox kernel) - k3s on bare metal (just to try), no VMs
- Workers: wyse1, wyse2 (Ubuntu)

Goal:
- Run workloads across all nodes

Observation:
- Some pods (nginx) failed when scheduled on opti1
- Same workloads worked correctly on wyse nodes

---

## Problem

Pods on opti1:

- Status: Running
- But application not working
- Logs showed errors:

socketpair() failed (13: Permission denied)

Same container image worked on other nodes

---

## Troubleshooting

1. Validate pod behavior across nodes

kubectl get pods -o wide  

→ Same workload:
- Works on wyse nodes
- Fails on opti1

---

2. Inspect logs

kubectl logs <pod>  

→ nginx errors:
socketpair() failed (13: Permission denied)

---

3. Compare environments

Key difference:
- opti1 → Proxmox kernel
- wyse → standard Ubuntu kernel

→ Issue likely related to:
- kernel features
- container runtime constraints
- security restrictions

---

## Interpretation

Kubernetes considered the pod healthy because:

- container started successfully
- main process still running

But:
- application inside container was partially broken

→ No readiness/liveness probe → issue not detected by Kubernetes

---

## Fix / Decision

Instead of debugging kernel/runtime deeply:

Decision:
- Do not schedule workloads on opti1

Apply taint:

kubectl taint nodes opti1 node-role.kubernetes.io/control-plane=:NoSchedule

---

## Result

- Workloads scheduled only on wyse1 / wyse2
- Applications run correctly
- Cluster stable

---

## Root Cause

Likely incompatibility between:

- Proxmox kernel
- container runtime / security model

(Not fully investigated – out of scope for initial setup)

---

## Key Takeaways

- "Running" ≠ application healthy
- Always validate behavior inside the container
- Node heterogeneity can introduce subtle issues
- Control plane nodes should not necessarily run workloads

---

## Preventive Actions

- Use homogeneous nodes for workloads when possible
- Add readiness/liveness probes in deployments
- Taint control plane nodes by default
- Validate workloads on each node type early

---

## Conclusion

Issue was node-specific (opti1), not cluster-wide.

→ Quick mitigation via taint allowed stable cluster operation without blocking progress.
