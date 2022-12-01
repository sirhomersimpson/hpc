resource "oci_core_instance" "bastion" {
  depends_on          = [oci_core_subnet.public-subnet]
  availability_domain = var.ad
  compartment_id      = var.targetCompartment
  shape               = var.bastion_shape
  display_name        = "${local.cluster_name}-bastion"

  shape_config {
    ocpus = var.bastion_instance_ocpus
    memory_in_gbs = var.bastion_instance_memgb
  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_key}\n${tls_private_key.ssh.public_key_openssh}"
    user_data           = base64encode(data.template_file.user_data.rendered)
  }
  source_details {
    source_id   = var.bastion_image
    source_type = "image"
  }

  create_vnic_details {
    subnet_id = local.bastion_subnet_id
  }
}

# configure bastion for keys, ansible
resource "null_resource" "bastion_configuration_keys" {
  depends_on = [oci_core_instance.bastion]
  triggers = {
    #id = oci_core_instance.bastion.id
    always_run = timestamp()
  }
  # Step 1.Copy keys to bastion
  provisioner "file" {
    content     = tls_private_key.ssh.private_key_pem
    destination = "/home/${var.bastion_username}/.ssh/id_rsa"
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
  # Step 2. Copy private keys to bastion
  provisioner "file" {
    content     = tls_private_key.ssh.public_key_openssh
    destination = "/home/${var.bastion_username}/.ssh/id_rsa.pub"
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  # Step 3. Copy ssh_config over to bastions
  provisioner "file" {
    source      = "${path.module}/files/ssh_config"
    destination = "/home/${var.bastion_username}/.ssh/config"
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  # Step 4. Chmod public/private keys to 600
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/${var.bastion_username}/.ssh/id_rsa",
      "chmod 600 /home/${var.bastion_username}/.ssh/id_rsa.pub",
    ]
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
}

resource "null_resource" "bastion_config_ansible" {
  depends_on = [oci_core_instance.bastion]
  triggers = {
    #id = oci_core_instance.bastion.id
    always_run = timestamp()
  }

  # Step 1. Create directory for oci-hpc
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/oci-hpc",
      "sudo chown ${var.bastion_username}:${var.bastion_username} /opt/oci-hpc/",
      "sudo mkdir -p /etc/ansible",
      "sudo chown ${var.bastion_username}:${var.bastion_username} /etc/ansible/",
      "mkdir -p /opt/oci-hpc/bin",
      "mkdir -p /opt/oci-hpc/playbooks"
    ]
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
  # Step 2. Copy playbooks over
  provisioner "file" {
    source      = "${path.module}/files/ansible.cfg"
    destination = "/etc/ansible/ansible.cfg"
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  # Step 3. Copy playbooks over
  provisioner "file" {
    source      = "playbooks"
    destination = "/opt/oci-hpc/"
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  # Step 4. Run script to configure bastion to configure itself for ansible
  provisioner "file" {
    source      = "${path.module}/files/configure_bastion.sh"
    destination = "/opt/oci-hpc/bin/configure_bastion.sh"
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod a+x /opt/oci-hpc/bin/configure_bastion.sh",
      "/opt/oci-hpc/bin/configure_bastion.sh"
    ]
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
}

# Resource runs on bastion - for CC configuration
resource "null_resource" "bastion_create_inventory_file" {
  depends_on = [
    null_resource.bastion_config_ansible,
    null_resource.bastion_configuration_keys,
    oci_core_instance.bastion,
  ]
  triggers = {
    cluster_instances = join(", ", local.cluster_instances_names)
  }
  # Step 1 - configure ansible hosts file
  # inventory.tpl construct used to get all CC ips and used to create the ansible inventory file
  provisioner "file" {
    content = templatefile("${path.module}/files/inventory.tpl", {
      bastion_name = oci_core_instance.bastion.display_name,
      bastion_ip   = oci_core_instance.bastion.private_ip,
      compute      = var.node_count > 0 ? zipmap(local.cluster_instances_names, local.cluster_instances_ips) : zipmap([], [])
      username     = var.bastion_username,
      shape        = var.cluster_shape
      cluster_name = local.cluster_name
    })
    destination = "/opt/oci-hpc/playbooks/inventory"
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp /opt/oci-hpc/playbooks/inventory /etc/ansible/hosts",
    ]
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  # Step 2 create a hosts of all private ips
  provisioner "file" {
    content     = var.node_count > 0 ? join("\n", local.cluster_instances_ips) : "\n"
    destination = "/tmp/hosts"
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
}

# Runs the ansible script on the bastion to configure the cn nodes
resource "null_resource" "run_ansible_from_bastion" {
  depends_on = [oci_core_instance.bastion,
    null_resource.bastion_config_ansible,
    null_resource.bastion_create_inventory_file,
  ]
  triggers = {
    id = oci_core_instance.bastion.id
    #always_run = timestamp()
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/oci-hpc",
      "sudo chown ${var.bastion_username}:${var.bastion_username} /opt/oci-hpc/",
      "mkdir -p /opt/oci-hpc/bin",
    ]
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  provisioner "file" {
    source      = "${path.module}/files/run_ansible_playbook.sh"
    destination = "/opt/oci-hpc/bin/run_ansible_playbook.sh"
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/oci-hpc/bin/run_ansible_playbook.sh",
      "timeout 2h /opt/oci-hpc/bin/run_ansible_playbook.sh",
    ]
    connection {
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
}
