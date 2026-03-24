# Homelab — DevOps Learning Platform

## Context
Transitioning from software engineering to DevOps/Cloud, this homelab is used to build hands-on experience with infrastructure, networking and Kubernetes.

## Hardware
- Optiplex 7050 (Proxmox)
- 2x Wyse 5070 (Ubuntu Server)
- MacBook Pro (management node)

## Network Design
- Static IP addressing (no DHCP dependency)
- Fully operational LAN without router
- Standardized SSH access (non-root user + sudo)
- Freebox (internet router) used as default gateway
- Mac can act as NAT fallback via iPhone tethering

## Architecture

## Normal Mode

```mermaid
flowchart TD
    I[Internet]
    F[Freebox<br/>Internet Router / Default Gateway]
    S[LAN Switch]

    M[MacBook Pro<br/>Admin node<br/>AX88179A<br/>192.168.1.10]
    O[opti1<br/>Proxmox host<br/>vmbr0<br/>192.168.1.11]
    W1[wyse1<br/>Ubuntu Server<br/>192.168.1.12]
    W2[wyse2<br/>Ubuntu Server<br/>192.168.1.13]

    I --> F
    F --> S

    S --> M
    S --> O
    S --> W1
    S --> W2
```

## Fallback Mode

```mermaid
flowchart TD
    I[Internet]
    P[iPhone 5G<br/>Backup Internet Link]
    M[MacBook Pro<br/>Admin node / NAT gateway<br/>AX88179A<br/>192.168.1.10]
    S[LAN Switch]

    O[opti1<br/>Proxmox host<br/>vmbr0<br/>192.168.1.11]
    W1[wyse1<br/>Ubuntu Server<br/>192.168.1.12]
    W2[wyse2<br/>Ubuntu Server<br/>192.168.1.13]

    I --> P
    P -. USB tethering .-> M
    M --> S

    S --> O
    S --> W1
    S --> W2
```

## Key Learnings
- DHCP failure can break local connectivity (internet router was KO)
- Static IP ensures resilience
- Clear separation between LAN and internet access
- Importance of consistent access (SSH + users)

## Next Steps
- Kubernetes cluster (k3s)
- Infrastructure automation (Terraform / Ansible)
