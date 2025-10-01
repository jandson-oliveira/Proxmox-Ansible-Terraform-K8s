PROXMOX_URL = "https:///api2/json"
PROXMOX_USER = ""
#PROXMOX_TOKEN = ""
PUBLIC_SSH_KEY = ""
target_nodes = ["pve1", "pve2"]
vm_template_name = "ubuntu-2204-cloud-template"


#template_vmid_by_node = {
#  "pve1" = 9000
#  "pve2" = 9001
#}

master_ips = ["192.168.18.200", "192.168.18.220"]
worker_ips = ["192.168.18.240", "192.168.18.245", "192.168.18.250", "192.168.18.230"]