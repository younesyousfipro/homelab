# Ansible Playbooks – k3s Cluster Setup

## Overview

This Ansible setup configures a k3s cluster on existing machines:

- one control plane node (`k3s_control_plane`)
- multiple worker nodes (`k3s_workers`)

The cluster runs on a mix of:

- virtual machines (provisioned via Terraform on Proxmox)
- bare metal nodes (Dell Wyse thin clients)

All nodes are configured uniformly through Ansible.

---

## What it does

- Bootstraps all nodes:
  - updates apt cache
  - installs required packages (e.g. curl)

- Installs k3s control plane:
  - runs k3s server
  - ensures service is running
  - retrieves cluster join token

- Installs k3s workers:
  - joins nodes to control plane using token

- Validates cluster:
  - checks node status via kubectl

---

## Structure

inventory/
hosts.yml

playbooks/
bootstrap.yml
k3s-server.yml
k3s-agent.yml
k3s-validate.yml
site.yml

---

## Design choices

- Single entrypoint: `site.yml` orchestrates all steps
- Separation of concerns:
  - bootstrap = base system setup
  - server = control plane installation
  - agent = worker join
  - validate = cluster verification
- Uses `hostvars` to share k3s token between plays
- Idempotent execution using `creates` and Ansible modules
- Same configuration applied to both VMs and bare metal nodes
- No secrets stored on disk

---

## Requirements

- Ansible installed on control machine
- SSH access to all nodes
- Sudo privileges on target machines
- Python installed on nodes

---

## Usage

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

---

## Validation

Cluster state is verified automatically at the end of execution:
```bash
k3s kubectl get nodes
```