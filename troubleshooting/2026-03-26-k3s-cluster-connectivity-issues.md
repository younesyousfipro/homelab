# 2026-03-26 – k3s Multi-Node Cluster: Intermittent Connectivity (Flannel / UFW)

## Context

Setup of a first k3s multi-node cluster in a homelab:

- Control plane: opti1
- Workers: wyse1, wyse2
- Network: LAN (192.168.1.0/24)
- CNI: Flannel (VXLAN)

Cluster deployment succeeded:
- Nodes joined
- Pods running across nodes
- Service (NodePort) created

Issue:
- External access via NodePort was intermittent (~1/2 success)

---

## Troubleshooting

1. Validate Kubernetes objects

kubectl get pods -o wide  
kubectl get svc  
kubectl get endpoints nginx  

→ All healthy (pods, service, endpoints)

2. Test direct pod connectivity

curl http://10.42.x.x  

Observation:
- Local pod → OK
- Remote pod → FAIL

→ Inter-node pod communication broken

3. Interpretation

Service load-balances across endpoints:
- Local pod → works
- Remote pod → fails

→ Explains intermittent behavior

4. Investigate host firewall

sudo ufw status  
grep DEFAULT_FORWARD_POLICY /etc/default/ufw  

Findings:
- UFW active
- Forward policy = DROP
- VXLAN port (UDP 8472) not allowed

---

## Fix

On each worker node:

sudo nano /etc/default/ufw  
→ DEFAULT_FORWARD_POLICY="ACCEPT"  

sudo ufw reload  

sudo ufw allow 8472/udp  

---

## Result

- Pod-to-pod communication works across nodes
- NodePort access stable
- No more intermittent failures

---

## Root Cause

Host firewall incompatible with Kubernetes networking:

- FORWARD traffic blocked → inter-node routing broken
- VXLAN (UDP 8472) blocked → overlay network incomplete

---

## Key Takeaways

- Kubernetes depends on host network configuration
- Intermittent behavior = often partial network failure
- Always test pod-to-pod connectivity directly

---

## Preventive Checklist

- CREATE A FIREWALL CHECKLIST IN DOCUMENTATION
- FORWARD policy = ACCEPT  
- UDP 8472 open (Flannel VXLAN)  
- Inter-node traffic allowed  
- No restrictive host firewall rules  

---

## Conclusion

Cluster was correctly deployed; issue was network-level.

→ Double check for network prerequisites (equivalent to cloud firewall rules).
