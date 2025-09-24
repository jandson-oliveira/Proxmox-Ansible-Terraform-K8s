# Projeto: Kubernetes com Proxmox, Terraform e Ansible

Este documento é um guia completo para provisionar um cluster Kubernetes de alta disponibilidade em um ambiente Proxmox VE, utilizando uma abordagem de Infraestrutura como Código (IaC).

### Arquitetura do Cluster

A infraestrutura foi projetada para ser resiliente e escalável, consistindo em:

-   **Plano de Controle (HA):** 2 nós master para garantir a disponibilidade da API do Kubernetes.
-   **Plano de Dados:** 2 nós worker para a execução das cargas de trabalho (aplicações).
-   **Balanceador de Carga:** 1 nó dedicado com **HAProxy** para distribuir o tráfego entre os masters.
-   **Rede dos Pods:** **Flannel CNI** para a comunicação entre os contêineres.
-   **Container Runtime:** **Containerd** como o ambiente de execução dos contêineres.

### Tecnologias Utilizadas

| Tecnologia | Finalidade |
| :--- | :--- |
| **Proxmox VE** | Plataforma de virtualização onde as VMs do cluster são criadas. |
| **Terraform** | Ferramenta de IaC para provisionar e gerenciar a infraestrutura (VMs). |
| **Ansible** | Ferramenta de automação para configurar o S.O. e instalar o Kubernetes. |
| **Kubernetes** | Orquestrador de contêineres para gerenciar o ciclo de vida das aplicações. |
| **Ubuntu 22.04** | Sistema Operacional base para todos os nós do cluster. |

---

## Guia de Implementação

### Pré-requisitos

Garanta que seu ambiente atende aos seguintes critérios antes de começar:

1.  **Servidor Proxmox VE:**
    -   Totalmente funcional e acessível pela rede.
    -   Recursos de CPU, RAM e disco suficientes para 7 VMs.
    -   Uma *network bridge* (ex: `vmbr0`) configurada para a rede das VMs.

2.  **Máquina Local (de Controle):**
    -   `terraform` (versão >= 1.0) instalado.
    -   `ansible` (versão >= 2.9) instalado.
    -   Um par de chaves SSH gerado (geralmente em `~/.ssh/id_rsa` e `~/.ssh/id_rsa.pub`).

### Passo 1: Preparar o Template Proxmox

Um template com `cloud-init` é crucial para a automação. Execute os comandos abaixo para criar um template do Ubuntu 22.04.

# 1. Baixar a imagem cloud oficial do Ubuntu Jammy Jellyfish
echo "Baixando a imagem cloud do Ubuntu 22.04..."
wget -O /tmp/jammy-server-cloudimg-amd64.img [https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img](https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img)

# 2. Criar uma nova VM base com ID 9000
qm create 9000 --name "ubuntu-2204-cloud-template" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --ostype l26

# 3. Importar o disco baixado para o storage 'local-lvm'
qm importdisk 9000 /tmp/jammy-server-cloudimg-amd64.img local-lvm

# 4. Anexar o disco à VM como um dispositivo SCSI na controladora virtio-scsi
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# 5. Adicionar a unidade de CD-ROM para ser usada pelo cloud-init
qm set 9000 --ide2 local-lvm:cloudinit

# 6. Definir o novo disco SCSI como a principal opção de boot
qm set 9000 --boot order=scsi0

# 7. Habilitar o QEMU Guest Agent para comunicação com o hypervisor
qm set 9000 --agent enabled=1

# 8. Converter a VM em um template para que não possa ser iniciada, apenas clonada
qm template 9000


### Passo 2: Configurar Variáveis de Ambiente

O Terraform precisa de credenciais para se conectar à API do Proxmox.

1.  **Exporte o segredo do Token da API** como uma variável de ambiente no seu terminal. **Não salve segredos em arquivos de texto.**

    ```bash
    export TF_VAR_PROXMOX_TOKEN="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    ```

### Passo 3: Executar a Implantação

O script `setup.sh` orquestra a execução do Terraform e do Ansible em sequência.


# 1. Dê permissão de execução ao script
chmod +x scripts/setup.sh

# 2. Execute o script para iniciar a implantação completa do cluster
./scripts/setup.sh

# 3. Destruição do Ambiente
Para remover completamente todos os recursos criados por este laboratório, use o script destroy.sh.

# Dê permissão de execução
chmod +x scripts/destroy.sh

# Execute o script de destruição
./scripts/destroy.sh

### Passo 4: Acessar o Cluster
Após a conclusão, o arquivo de configuração do Kubernetes (kubeconfig) estará no primeiro nó master.

Gerenciamento via sua máquina local (Recomendado):

# Copie o kubeconfig do master para sua máquina local
scp ubuntu@<IP_DO_MASTER_1>:~/.kube/config ~/.kube/config-homelab

# Exporte a variável KUBECONFIG para que o kubectl use este arquivo
export KUBECONFIG=~/.kube/config-homelab

# Verifique a saúde do cluster
kubectl get nodes
kubectl cluster-info


### Comandos Importantes
Entre no diretório terraform para rodar comandos que podem ajudar na resolução de algum problema.

terraform init: Inicializa o diretório, baixando provedores e módulos.

terraform validate: Verifica a sintaxe dos arquivos de configuração.

terraform plan: Cria um plano de execução, mostrando o que será alterado.

terraform apply: Aplica as alterações para criar ou atualizar a infraestrutura.

terraform destroy: Destrói toda a infraestrutura gerenciada.

terraform fmt: Reformata os arquivos para um estilo padrão.

terraform output: Exibe os valores das variáveis de saída.

terraform graph: Gera um grafo visual das dependências dos recursos.

terraform providers: Exibe a árvore de provedores utilizados.

terraform destroy -target='...[i]': Destrói uma instância específica de um recurso.

terraform apply -target='...': Aplica alterações em um recurso específico.

terraform destroy -target='...' -auto-approve: Destrói um recurso sem pedir confirmação.
