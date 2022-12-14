# Purpose 
Ansible playbook that runs on the bastion. The playbook configures the cluster nodes for RDMA. 

# Code structure  / Design 

- site.yml runs all the roles in the play.
- the inventory is generated by TF using the inventory.tpl (under files/) and is stored in /etc/ansible/hosts on the VM

## Roles 

| Binary/Package/Directory | Functionality                                                                                              |
|--------------------------|------------------------------------------------------------------------------------------------------------|
| copy-keys                | copy pkeys to .ssh for each of the CC nodes                                                                |
| etc-hosts                | It is a tricky logic but it creates /etc/hosts for the bastion and cc nodes                                |
| hostname                 | sets the hostname (you will see that TF has set OCI hostname <pet_name>-bastion, <pet_name>-cc-node-0,...) |
| packages                 | Install OCI and other utils                                                                                |
| rdma-configure           | rdma-configure - switches on the rdma service on the node                                                  |


# Ansible cheatsheet to be run from bastion

## Ping - to check health of CC + bastion 
```angular2html
ANSIBLE_HOST_KEY_CHECKING=False ansible -p ~/.ssh/id_rsa -m ping -m bastion
ANSIBLE_HOST_KEY_CHECKING=False ansible -p ~/.ssh/id_rsa -m ping -m comptute
ANSIBLE_HOST_KEY_CHECKING=False ansible -p ~/.ssh/id_rsa -m ping -m all 
```

## Get inventory
```angular2html
ANSIBLE_HOST_KEY_CHECKING=False ansible -p ~/.ssh/id_rsa --list-hosts
```

## Gather facts
```angular2html
ansible all -m gather_facts --tree /tmp/facts
```

## Check syntax 
```angular2html
ansible-playbook site.yml --syntax-check
```

### Check diff - dry run
```angular2html
ansible-playbook  site.yml --check --diff
```

### Check list of defaults modules
```angular2html
ansible-doc -F
```
