variable "proxmox_node_name" {
  description = "Name of the Proxmox node"
  type        = string
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "template_vm_id" {
  description = "VM ID of the Proxmox template used for cloning"
  type        = number
}

variable "vm_gateway" {
  description = "Default gateway for the VMs"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key injected via cloud-init"
  type        = string
}

variable "vm_username" {
  description = "Default username injected via cloud-init"
  type        = string
}

variable "vm_disk_size" {
  description = "Disk size for VMs"
  type        = number
}

variable "cp_name" {
  description = "Name of the control plane VM"
  type        = string
}

variable "cp_vm_id" {
  description = "VM ID of the control plane VM"
  type        = number
}

variable "cp_ip" {
  description = "IPv4 address of the control plane VM"
  type        = string
}

variable "cp_memory" {
  description = "RAM of the control plane VM in MB"
  type        = number
}

variable "cp_cores" {
  description = "Number of vCPUs for the control plane VM"
  type        = number
}

variable "worker_name" {
  description = "Name of the worker VM"
  type        = string
}

variable "worker_vm_id" {
  description = "VM ID of the worker VM"
  type        = number
}

variable "worker_ip" {
  description = "IPv4 address of the worker VM"
  type        = string
}

variable "worker_memory" {
  description = "RAM of the worker VM in MB"
  type        = number
}

variable "worker_cores" {
  description = "Number of vCPUs for the worker VM"
  type        = number
}