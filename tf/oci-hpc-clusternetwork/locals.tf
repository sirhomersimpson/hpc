locals {
  // ips of the instances
  cluster_instances_ips   = var.cluster_network ? data.oci_core_instance.cluster_network_instances.*.private_ip : data.oci_core_instance.instance_pool_instances.*.private_ip
  cluster_instances_names = var.cluster_network ? data.oci_core_instance.cluster_network_instances.*.display_name : data.oci_core_instance.instance_pool_instances.*.display_name

  // vcn id derived either from created vcn or existing if specified
  vcn_id = element(concat(oci_core_vcn.vcn.*.id, [""]), 0)

  // subnet id derived either from created subnet or existing if specified
  subnet_id = element(concat(oci_core_subnet.private-subnet.*.id, [""]), 0)

  // subnet id derived either from created subnet or existing if specified
  bastion_subnet_id = element(concat(oci_core_subnet.public-subnet.*.id, [""]), 0)

  cluster_name = random_pet.name.id
}
