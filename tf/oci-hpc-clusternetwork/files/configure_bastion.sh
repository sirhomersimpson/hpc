#!/bin/bash

# Global variables
MAX_RETRY_COUNT=32

# Source as environments variables - we will use $ID in this script
# Example
#   NAME="Oracle Linux Server"
#   VERSION="7.9"
#   ID="ol"
source /etc/os-release

# Default repo
repo="ol7_developer_EPEL"
log_file="/tmp/configure_bastion.log"

# Helper function for retry
function retry {
    local i=0
    # Max number of times we retry
    local retries=$MAX_RETRY_COUNT
    cmd=$*
    printf "[retry] Running command : %s $cmd\n" | tee -a $log_file
    for i in $(seq 0 $retries); do
        if [[ $i -eq $retries ]]; then
          printf "ERROR: Too many failures of - %s: $cmd giving up\n" | tee -a $log_file
          exit 1
        else
          eval "$cmd"
          return_status=$?
          if [[ return_status -eq 0 ]]; then
            break
          else
              printf "WARNING: Failed attempting - %s $cmd - retrying: %d $i\n" | tee -a $log_file
          fi
          sleep 1
        fi
    done
}


# Wait for Cloud Init to finish
function wait_for_cloud_to_finish {
  printf "[wait_for_cloud_to_finish] waiting for cloud_init to finish\n" | tee -a $log_file
  sudo cloud-init status --wait

}

# Get repo
function get_repo_for_os {
  printf "[get_repo_for_os] ID: %s $ID\n" | tee -a $log_file
  if [[ $ID == "ol" ]] ; then
    repo="ol7_developer_EPEL"
  elif [[ $ID == "centos" ]] ; then
    repo="epel"
  fi
  printf "[get_repo_for_os] repo: %s $repo\n" | tee -a $log_file
  # to ensure existing enabled repos are available.
  if [[ $ID == "ol" ]] ; then
    sudo osms unregister
    printf "[get_repo_for_os] unregistered osms for  %s $ID\n" | tee -a $log_file
  fi
}

# Install packages
function install_packages {
  # Step 1. Get repo as per os
  get_repo_for_os
  # Step 2. Install packages per repo
  # The following packages are installed: ansible, python-netaddr
  printf "[install_packages] Installing package for %s $ID %s $VERSION_ID\n" | tee -a $log_file
  sudo python3 -m pip install ansible

}

# Optimized ansible configs
function configure_ansible_cfg {
  threads=$(nproc)
  forks=$((threads * 8))
  printf "[configure_ansible_cfg] threads: %d $threads forks: %d $forks\n" | tee -a $log_file
  sudo sed -i "s/^#forks.*/forks = ${forks}/" /etc/ansible/ansible.cfg
  sudo sed -i "s/^#fact_caching=.*/fact_caching=jsonfile/" /etc/ansible/ansible.cfg
  sudo sed -i "s/^#fact_caching_connection.*/fact_caching_connection=\/tmp\/ansible/" /etc/ansible/ansible.cfg
  sudo sed -i "s/^#bin_ansible_callbacks.*/bin_ansible_callbacks=True/" /etc/ansible/ansible.cfg
  sudo sed -i "s/^#stdout_callback.*/stdout_callback=yaml/" /etc/ansible/ansible.cfg
  sudo sed -i "s/^#retries.*/retries=5/" /etc/ansible/ansible.cfg
  sudo sed -i "s/^#connect_timeout.*/connect_timeout=300/" /etc/ansible/ansible.cfg
  sudo sed -i "s/^#command_timeout.*/command_timeout=120/" /etc/ansible/ansible.cfg
}

function log_when_completed {
  value=$(date --utc +%m_%d_%Y_%TZ)
  echo "$value" > /tmp/.configure_bastion_status
}

function main {
  # Step 1. Wait for cloud-init to finish
  wait_for_cloud_to_finish

  # Step 2. install packages
  install_packages

  # Step 3. install packages
  configure_ansible_cfg

  # Step 4. Log completed time
  log_when_completed
}

main
