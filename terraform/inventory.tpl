# terraform/inventory.tpl
all:
  children:
    k8s_cluster:
      children:
        kube_control_plane:
          hosts:
%{ for ip in master_ips ~}
            ${ip}:
%{ endfor ~}
        kube_node:
          hosts:
%{ for ip in worker_ips ~}
            ${ip}:
%{ endfor ~}
        etcd:
          hosts:
%{ for ip in master_ips ~}
            ${ip}:
%{ endfor ~}
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'