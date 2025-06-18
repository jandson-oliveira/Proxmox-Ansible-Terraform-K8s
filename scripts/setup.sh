# scripts/setup.sh
#!/bin/bash

set -e

echo "Setting up Kubernetes Home Lab with Local Repository..."

# Check if required tools are installed
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed. Aborting." >&2; exit 1; }
command -v ansible >/dev/null 2>&1 || { echo "Ansible is required but not installed. Aborting." >&2; exit 1; }

# Create terraform.tfvars if it doesn't exist
if [ ! -f /Users/varun/Documents/git/varunshomelab/terraform/terraform.tfvars ]; then
    echo "Please create terraform/terraform.tfvars from terraform.tfvars.example"
    exit 1
fi

# Initialize and apply Terraform
echo "Initializing Terraform..."
cd terraform
terraform init

echo "Planning Terraform deployment..."
terraform plan

echo "Applying Terraform configuration..."
terraform apply -auto-approve

echo "Waiting for VMs to be ready..."
sleep 1

# Run Ansible playbook
echo "Running Ansible playbook..."
cd ../ansible

# # First setup the repository server
# echo "Setting up repository server..."
# ansible-playbook -i inventory/hosts.yml site.yml --limit repository

# echo "Waiting for repository services to start..."
# sleep 30

# Then setup the rest of the infrastructure
echo "Setting up Kubernetes cluster..."
ansible-playbook -i inventory/hosts.yml site.yml --skip-tags repository

echo "Kubernetes cluster setup complete!"
echo ""
#echo "Repository Server: http://$(terraform output -raw repo_server_ip)"
echo "Docker Registry: http://$(terraform output -raw repo_server_ip):5000"
echo "Registry UI: http://$(terraform output -raw repo_server_ip):8081"
echo "Portainer: http://$(terraform output -raw repo_server_ip):9000"
echo ""
echo "Access your cluster with: kubectl --kubeconfig ~/.kube/config get nodes"