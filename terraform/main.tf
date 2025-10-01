terraform {
  required_version = ">= 0.13.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc04"
      version = "3.0.2-rc04"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.PROXMOX_URL
  pm_api_token_id     = var.PROXMOX_USER
  pm_api_token_secret = var.PROXMOX_TOKEN
  pm_tls_insecure     = true
}

# ===================================================================
# Variáveis de Configuração
# ===================================================================

variable "PROXMOX_URL" {
  description = "Proxmox API URL"
  type        = string
}

variable "PROXMOX_USER" {
  description = "Proxmox username"
  type        = string
}

variable "PROXMOX_TOKEN" {
  description = "Proxmox token"
  type        = string
  sensitive   = true
}

variable "PUBLIC_SSH_KEY" {
  description = "SSH public key for VM access"
  type        = string
}

variable "target_nodes" {
  description = "A list of ONLINE Proxmox node names."
  type        = list(string)
  default     = ["pve1"]
}

variable "vm_template_name" {
  description = "The name of the VM template to clone."
  type        = string
  default     = "ubuntu-2204-cloud-template"
  default     = "ubuntu-2204-cloud-template"
}

variable "master_ips" {
  description = "Lista de IPs para os nós master."
  type        = list(string)
  default     = []
  default     = []
}

variable "worker_ips" {
  description = "Lista de IPs para os nós worker."
  type        = list(string)
  default     = []
  default     = []
}

# ===================================================================
# Nós Master
# ===================================================================
resource "proxmox_vm_qemu" "k8s_master" {
  count = length(var.master_ips)
  name  = "k8s-master-${count.index + 1}"
  

  target_node = element(var.target_nodes, count.index % length(var.target_nodes))

  clone      = var.vm_template_name
  full_clone = true

  
  cpu {
    cores   = 2
    sockets = 1
  }
  memory = 2048
  agent  = 1
  vmid   = "300${count.index + 1}"
  onboot = true

  # Display
  vga {
    type   = "std"
    memory = 16
  }

  # Network
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  scsihw = "virtio-scsi-single"

  # Disk
  disks {
    ide {
      ide2 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size      = 20
          cache     = "writeback"
          storage   = "local-lvm"
          replicate = false
        }
      }
    }
  }

  boot = "order=scsi0"

  # Cloud-init
  os_type    = "cloud-init"
  ciuser     = "ubuntu"
  cipassword = "ubuntu"
  sshkeys    = var.PUBLIC_SSH_KEY
  ipconfig0  = "ip=${var.master_ips[count.index]}/24,gw=192.168.18.1"
  ipconfig0  = "ip=${var.master_ips[count.index]}/24,gw=192.168.18.1"
  nameserver = "1.1.1.1"
}


# ===================================================================
# Nós Worker
# ===================================================================
resource "proxmox_vm_qemu" "k8s_worker" {
  count = length(var.worker_ips)
  name  = "k8s-worker-${count.index + 1}"
  
  
  target_node = element(var.target_nodes, count.index % length(var.target_nodes))

  clone      = var.vm_template_name
  full_clone = true

  
  cpu {
    cores   = 2
    sockets = 1
  }
  memory = 4096
  agent  = 1
  vmid   = "400${count.index + 1}"
  onboot = true

  # Display
  vga {
    type   = "std"
    memory = 16
  }

  # Network
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  scsihw = "virtio-scsi-single"
  
  # Disk
  disks {
    ide {
      ide2 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size      = 20
          cache     = "writeback"
          storage   = "local-lvm"
          replicate = false
        }
      }
    }
  }

  boot = "order=scsi0"

  # Cloud-init
  os_type    = "cloud-init"
  ciuser     = "ubuntu"
  cipassword = "ubuntu"
  sshkeys    = var.PUBLIC_SSH_KEY
  ipconfig0  = "ip=${var.worker_ips[count.index]}/24,gw=192.168.18.1"
  ipconfig0  = "ip=${var.worker_ips[count.index]}/24,gw=192.168.18.1"
  nameserver = "1.1.1.1"

  lifecycle {
    ignore_changes = [network]
  }
}
# ===================================================================
# Outputs e Inventário Ansible
# ===================================================================
output "master_ips" {
  value = var.master_ips
  value = var.master_ips
}

output "worker_ips" {
  value = var.worker_ips
  value = var.worker_ips
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    master_ips = var.master_ips
    worker_ips = var.worker_ips
    master_ips = var.master_ips
    worker_ips = var.worker_ips
  })
  filename = "../ansible/inventory/hosts.yml"
}