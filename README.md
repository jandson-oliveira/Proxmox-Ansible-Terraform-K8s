# README.md
# Kubernetes Home Lab with Proxmox, Terraform, and Ansible

This project sets up a complete Kubernetes cluster in a Proxmox home lab environment using Infrastructure as Code principles.

## Architecture

- **3 Master nodes** (HA control plane)
- **3 Worker nodes**
- **1 Load balancer** (HAProxy)
- **Flannel CNI** for pod networking
- **Containerd** as container runtime

## Prerequisites

1. **Proxmox VE** server with:
   - Ubuntu 22.04 template (cloud-init enabled)
   - Sufficient resources (7 VMs total)
   - Network bridge configured

2. **Local machine** with:
   - Terraform >= 1.0
   - Ansible >= 2.9
   - SSH key pair generated

## Setup Instructions

### 1. Initial Repository Setup (First Time Only)

If this is your first deployment, set up the repository server first:

```bash
# Run the repository setup script
chmod +x scripts/setup-repository.sh
./scripts/setup-repository.sh --first-run
```

This creates the Ubuntu template and pre-populates the Docker registry.

### 2. Prepare Proxmox Template

If you already have a repository server, create the template using local images:

```bash
# Download from local repository
wget -O /tmp/jammy-server-cloudimg-amd64.img http://192.168.1.98/images/ubuntu-22.04-amd64.img

# Create VM and convert to template

root@catan:/var/lib/vz/template/iso# qm create 9000 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
root@catan:/var/lib/vz/template/iso# qm set 9000 --scsi0 local-lvm:0,import-from=/var/lib/vz/template/iso/jammy-server-cloudimg-amd64.img
root@catan:/var/lib/vz/template/iso# qm set 9000 --ide2 local-lvm:cloudinit
root@catan:/var/lib/vz/template/iso# qm set 9000 --boot order=scsi0
root@catan:/var/lib/vz/template/iso# qm template 9000

### 3. Configure Variables

Copy and edit the Terraform variables:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform.tfvars` with your Proxmox details:

PROXMOX_URL = "https://your-proxmox-server:8006/api2/json"
PROXMOX_USER = "terraform@pve!provider"
PROXMOX_TOKEN = "put-api-token-here"
PUBLIC_SSH_KEY = "put-contents-of-id_rsa.pub"
target_node = "name-of-the-proxmox-node"


### 4. Deploy the Lab

Run the setup script:

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

This will:
1. Create VMs in Proxmox using Terraform
2. Setup the local repository server first
3. Generate Ansible inventory
4. Configure all nodes with Ansible using local repositories
5. Set up the Kubernetes cluster

### 5. Access the Cluster

The kubeconfig will be available on the first master node:

```bash
ssh ubuntu@192.168.1.100
kubectl get nodes
```

Or copy it to your local machine:

```bash
scp ubuntu@192.168.1.100:~/.kube/config ~/.kube/config-homelab
export KUBECONFIG=~/.kube/config-homelab
kubectl get nodes
```

# Network Configuration

- **Repository Server**: 192.168.1.98
- **Load Balancer**: 192.168.1.140
- **Masters**: 192.168.1.120-102
- **Workers**: 192.168.1.130-112
- **Pod Network**: 10.244.0.0/16

## Repository Services

The local repository server provides:

- **Docker Registry**: Private registry at `192.168.1.98:5000`
- **Ubuntu Cloud Images**: Local mirror at `http://192.168.1.98/images/`
- **APT Packages**: Local mirrors for Ubuntu, Kubernetes, and Docker packages
- **Web UI**: Registry management at `http://192.168.1.98:8081`
- **Portainer**: Container management at `http://192.168.1.98:9000`

## Monitoring

HAProxy stats are available at: http://192.168.1.140:8080/stats

## Cleanup

To destroy the entire lab:

```bash
chmod +x scripts/destroy.sh
./scripts/destroy.sh
```

## Repository Management

### Using the Local Docker Registry

Configure Docker to use the local registry:

```bash
# Add insecure registry to Docker daemon
sudo tee /etc/docker/daemon.json <<EOF
{
  "insecure-registries": ["192.168.1.98:5000"],
  "registry-mirrors": ["http://192.168.1.98:5000"]
}
EOF

sudo systemctl restart docker
```

Push images to local registry:

```bash
# Tag image for local registry
docker tag nginx:latest 192.168.1.98:5000/nginx:latest

# Push to local registry
docker push 192.168.1.98:5000/nginx:latest
```

### Managing Repository Content

Access the repository management interfaces:

- **Repository Status**: http://192.168.1.98
- **Docker Registry UI**: http://192.168.1.98:8081
- **Container Management**: http://192.168.1.98:9000
- **Cloud Images**: http://192.168.1.98/images/
- **APT Packages**: http://192.168.1.98/ubuntu/

### Updating Repository Content

To refresh images and packages:

```bash
# SSH to repository server
ssh ubuntu@192.168.1.98

# Update cloud images
cd /opt/repository/images
wget -O ubuntu-22.04-amd64.img https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Update APT mirrors
/opt/repository/create-apt-mirror.sh

# Restart services
cd /opt/repository
docker-compose restart
```

## Offline Operation

Once fully set up, the lab can operate completely offline:

1. **VM Templates**: Created from local cloud images
2. **Container Images**: Pulled from local Docker registry
3. **System Packages**: Installed from local APT mirrors
4. **Kubernetes Components**: Downloaded from local mirrors

## Customization

### Scaling

Modify the `count` parameters in `terraform/main.tf` to adjust the number of nodes.

### VM Resources

Adjust CPU, memory, and disk in the Terraform configuration as needed.

### Network Settings

Update IP ranges and network configuration in the Terraform variables.

## Troubleshooting

1. **VM Creation Issues**: Check Proxmox template exists and has cloud-init
2. **SSH Connection Issues**: Verify SSH key is correct and accessible
3. **Repository Issues**: Check repository server is running and accessible
4. **Package Installation Issues**: Verify local APT mirrors are populated
5. **Docker Registry Issues**: Check registry is running on port 5000
6. **Kubernetes Join Issues**: Check firewall rules and network connectivity
7. **Pod Network Issues**: Verify Flannel CNI installation from local registry

### Repository Server Debugging

Check repository services:

```bash
ssh ubuntu@192.168.1.98
docker ps -a                    # Check all containers
docker-compose logs -f          # View logs
sudo systemctl status nginx     # Check web server
curl http://localhost/images/    # Test local access
```

### Registry Debugging

Test Docker registry:

```bash
# Test registry API
curl http://192.168.1.98:5000/v2/_catalog

# Test image pull
docker pull 192.168.1.98:5000/nginx:latest
```

## Components

- **Terraform**: Infrastructure provisioning
- **Ansible**: Configuration management
- **Repository Server**: Local package and image hosting
- **Docker Registry**: Private container registry
- **Nginx**: Web server for repository access
- **Kubernetes**: Container orchestration
- **Containerd**: Container runtime
- **Flannel**: Pod networking
- **HAProxy**: Load balancing
- **Portainer**: Container management UI

## Architecture Benefits

- **Bandwidth Efficiency**: No repeated downloads from internet
- **Faster Deployments**: Local images and packages
- **Offline Capability**: Complete air-gapped operation possible
- **Version Control**: Consistent package versions across deployments
- **Cost Effective**: Reduced internet bandwidth usage
- **High Availability**: Local redundancy for critical components