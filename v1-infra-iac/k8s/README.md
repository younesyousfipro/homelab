# Kubernetes – Application Deployment (k3s Homelab)

## Overview

This step deploys a simple Hello World Python application on a k3s cluster and exposes it on the local network.

The application is:
- containerized (Docker)
- deployed via a Kubernetes Deployment
- exposed via a NodePort Service

---

## Architecture

```
Mac (client)
→ NodeIP:NodePort
→ Kubernetes Service (L4)
→ Pods (replicas)
→ Python app (port 8000)
```

---

## Resources

### Deployment

- Runs the application as multiple replicas
- Uses image from Docker Hub
- Ensures pods are always running

### Service (NodePort)

- Exposes the application on the LAN
- Provides load balancing across pods

---

## Apply manifests

```bash
kubectl apply -f k8s/base/deployment.yaml
kubectl apply -f k8s/base/service.yaml
```

---

## Verification

### Check pods

```bash
kubectl get pods -o wide
```

Expected:
- all pods in `Running`
- distributed across worker nodes

---

### Check deployment

```bash
kubectl get deployment hello-app
```

---

### Check service

```bash
kubectl get svc hello-app
```

Example output:

```
hello-app   NodePort   10.x.x.x   <none>   80:30007/TCP
```

---

### Check endpoints (critical)

```bash
kubectl get endpoints hello-app
```

Expected:
- list of pod IPs
- proves service correctly targets pods

---

## Test application

From your Mac:

```bash
curl http://<NODE_IP>:30007
```

Example:

```bash
curl http://192.168.1.12:30007
```

Expected response:

```json
{"message":"Hello World ..."}
```

---

## Debugging

### Describe pod

```bash
kubectl describe pod <pod-name>
```

---

### Check logs

```bash
kubectl logs <pod-name>
```

---

### Exec into pod

```bash
kubectl exec -it <pod-name> -- sh
```

---

### Restart deployment

```bash
kubectl rollout restart deployment hello-app
```

---

### Scale application

```bash
kubectl scale deployment hello-app --replicas=5
```

---

## Notes

- Pods are internal to the cluster (not directly accessible)
- Service provides stable access and load balancing
- NodePort exposes the service on each node
- Control plane is tainted (no workload scheduling)

---

## Current limitations

- NodePort used for simplicity (not production-grade)
- No Ingress / TLS
- No CI/CD yet

---

## Next steps

- Add Ingress (Traefik)
- Introduce namespaces (dev / staging / prod)
- Implement CI/CD (build → push → deploy)
- Add resource limits and autoscaling