proxmox_node_name   = "opti1"
template_vm_id      = 100
vm_gateway          = "192.168.1.254"
ssh_public_key_path = "/Users/younesyousfi/.ssh/id_ed25519_homelab.pub"
vm_username         = "younes"
vm_disk_size        = 30

cp_name   = "k3s-cp"
cp_vm_id  = 101
cp_ip     = "192.168.1.20"
cp_memory = 3072
cp_cores  = 2

worker_name   = "k3s-worker-1"
worker_vm_id  = 102
worker_ip     = "192.168.1.21"
worker_memory = 2048
worker_cores  = 1