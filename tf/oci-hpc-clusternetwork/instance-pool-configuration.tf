resource "oci_core_instance_configuration" "instance_pool_configuration" {
  count          = (!var.cluster_network) && (var.node_count > 0) ? 1 : 0
  compartment_id = var.targetCompartment
  display_name   = local.cluster_name

  instance_details {
    instance_type = "compute"
    launch_details {
      availability_domain = var.ad
      compartment_id      = var.targetCompartment
      create_vnic_details {
      }
      display_name = local.cluster_name
      freeform_tags = {
        "cluster_name"   = local.cluster_name
        "parent_cluster" = local.cluster_name
      }
      metadata = {
        ssh_authorized_keys = "${var.ssh_key}\n${tls_private_key.ssh.public_key_openssh}"
        user_data           = base64encode(data.template_file.user_data.rendered)
      }
      agent_config {
        is_management_disabled = true
      }
      shape = var.cluster_shape
      source_details {
        source_type = "image"
        image_id    = var.cluster_image
      }
    }
  }
  source = "NONE"
}
