# Networking Design

## Overview

This homelab is designed to run as a simple and resilient local network.

It can:
- operate without internet
- avoid dependency on DHCP
- use a fallback internet access if needed

---

## Topology

- Freebox (internet router)
- 2 Ethernet switches (cascaded)
- MacBook Pro (admin + fallback NAT)
- 3 nodes:
  - opti1 (Proxmox)
  - wyse1 (worker)
  - wyse2 (worker)

All devices are on the same LAN (Layer 2 network).

---

## IP Addressing

Static IPs are manually configured on each machine:

| Host     | IP Address     |
|----------|----------------|
| MacBook  | 192.168.1.10   |
| opti1    | 192.168.1.11   |
| wyse1    | 192.168.1.12   |
| wyse2    | 192.168.1.13   |

Subnet:
192.168.1.0/24

---

## Gateway

### Normal mode
- Default gateway: Freebox
- Used for internet access (updates, downloads)

### Fallback mode
- MacBook acts as a NAT gateway
- Internet via iPhone (USB tethering)

Flow:
Nodes → MacBook → iPhone → Internet

---

## Design Choices

- Static IPs instead of DHCP
- LAN must work without router
- Internet access is optional
- Simple and understandable setup

---
