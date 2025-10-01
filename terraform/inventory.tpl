
all:
  children:
    k8s_cluster:
      children:
        kube_control_plane:
          hosts:
%{ for i, ip in master_ips ~}
            k8s-master-${i+1}:
              ansible_host: ${ip}
%{ endfor ~}

        kube_node:
          hosts:
%{ for i, ip in worker_ips ~}
            k8s-worker-${i+1}:
              ansible_host: ${ip}
%{ endfor ~}

        etcd:
          hosts:
%{ for i, ip in master_ips ~}
            k8s-master-${i+1}:
              ansible_host: ${ip}
%{ endfor ~}

  vars:
    
    K8S_API_VIP: 192.168.18.55  
    keepalived_interface: eth0
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'