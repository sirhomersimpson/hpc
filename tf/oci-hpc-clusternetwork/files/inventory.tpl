[bastion]
${bastion_name} ansible_host=${bastion_ip} ansible_user=${username} role=bastion

[compute]
%{ for host, ip in compute ~}
${host} ansible_host=${ip} ansible_user=${username} role=compute
%{ endfor ~}

[all:children]
bastion
compute

[all:vars]
ansible_connection=ssh
shape=${shape}
cluster_name=${cluster_name}
