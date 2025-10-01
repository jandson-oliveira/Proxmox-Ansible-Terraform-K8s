#!/bin/bash

set -e

# ==============================================================================
# SCRIPT DE SETUP PARA O CLUSTER KUBERNETES
#
# Uso:
#   ./scripts/setup.sh                    # Executa TUDO: Terraform + Ansible completo
#   ./scripts/setup.sh debug-prereqs      # Executa o DEBUG: Terraform + Ansible focado
# ==============================================================================

ACTION=${1:-all}

# --- Lógica Principal ---

if [[ "$ACTION" == "all" ]]; then
    echo "MODO: Execução completa (Terraform + Ansible)"
    echo "---------------------------------------------"
    
    echo "Applying Terraform configuration to build infrastructure..."
    cd terraform
    terraform init
    terraform apply -auto-approve
    cd ..

    echo "Running full Ansible playbook..."
    cd ansible
    ansible-playbook -i inventory/hosts.yml site.yml
    cd ..

elif [[ "$ACTION" == "debug-prereqs" ]]; then
    echo "MODO: DEBUG - Testando apenas os pré-requisitos"
    echo "------------------------------------------------"
    
    echo "Applying Terraform configuration to ensure inventory is fresh..."
    cd terraform
    terraform init
    terraform apply -auto-approve
    cd .. 

    echo "Running focused Ansible playbook for prerequisites..."
    cd ansible
    ansible-playbook -i inventory/hosts.yml site.yml --tags prereqs --limit k8s-master-1
    cd ..
fi

echo ""
echo "Script finalizado."
echo ""