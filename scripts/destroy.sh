# scripts/destroy.sh
#!/bin/bash

set -e

echo "Destroying Kubernetes Home Lab..."

cd terraform
terraform destroy -auto-approve

echo "Lab environment destroyed!"

