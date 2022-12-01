#!/bin/bash

# Executes the ansible playbook from the bastion to configure the CN nodes

# Globals
playbook="/opt/oci-hpc/playbooks/site.yml"
log_file="/tmp/run_ansible_playbook.log"
retries=45
sleep_time=60

# Checks if ssh is on and outputs to log file all connected ips
# The diff between $log_file and /tmp/hosts is what is not connected
function wait_for_ssh_cn_nodes_are_up {
  printf "[check_ssh_for_cn_nodes_are_up] Checking if ssh is up\n" | tee -a $log_file
  hosts_ip=$(cat /tmp/hosts)

  for ip in ${hosts_ip}; do
    r=0
    printf "validating connection to: %s\n" "${ip}"

    while ! timeout 1s ssh  "${ip}" uptime ; do
      printf "Still waiting for %s ... Sleeping for %d seconds\n"  ${ip} $sleep_time | tee -a $log_file
      sleep $sleep_time
      r=$(($r + 1))
      if [[ $r -gt $retries ]]; then
        printf "Unable to connect to ... %s:\n"  "${ip}" | tee -a $log_file
        break;
      fi
    done
  done
  printf "[check_ssh_for_cn_nodes_are_up] All nodes are maybe connected - check logs %s:\n"  "$log_file" | tee -a $log_file

}

function run_ansible {
  # Save the setup for debugging
  #ANSIBLE_HOST_KEY_CHECKING=False ansible all -m setup --tree /tmp/ansible

  #Run the playbook
  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook $playbook
}
function main {
    wait_for_ssh_cn_nodes_are_up
    run_ansible
}

main
