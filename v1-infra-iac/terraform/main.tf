resource "proxmox_virtual_environment_vm" "k3s_cp" {
  name      = var.cp_name
  node_name = var.proxmox_node_name
  vm_id     = var.cp_vm_id

  clone {
    vm_id = var.template_vm_id
  }

  agent {
    enabled = true
  }

  memory {
    dedicated = var.cp_memory
  }

  cpu {
    cores = var.cp_cores
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = var.vm_disk_size
  }

  initialization {
    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
    }

    ip_config {
      ipv4 {
        address = "${var.cp_ip}/24"
        gateway = var.vm_gateway
      }
    }

    user_account {
      username = var.vm_username
      keys     = [trimspace(file(var.ssh_public_key_path))]
    }
  }
}

resource "proxmox_virtual_environment_vm" "k3s_worker_1" {
  name      = var.worker_name
  node_name = var.proxmox_node_name
  vm_id     = var.worker_vm_id

  clone {
    vm_id = var.template_vm_id
  }

  agent {
    enabled = true
  }

  memory {
    dedicated = var.worker_memory
  }

  cpu {
    cores = var.worker_cores
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = var.vm_disk_size
  }

  initialization {
    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
    }

    ip_config {
      ipv4 {
        address = "${var.worker_ip}/24"
        gateway = var.vm_gateway
      }
    }

    user_account {
      username = var.vm_username
      keys     = [trimspace(file(var.ssh_public_key_path))]
    }
  }
}