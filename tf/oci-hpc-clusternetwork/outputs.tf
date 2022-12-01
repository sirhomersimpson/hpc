output "bastion" {
  value = oci_core_instance.bastion.public_ip
}
output "private_ips" {
  value = join(" ", local.cluster_instances_ips)
}


# Debugging
#output "ssh_private_key_from_file" {
#  value = file("${path.module}/key.pem")
#}

#output "ssh_public_key_from_file" {
#  value = file("${path.module}/key.pem")
#}

#output "all-availability-domains-in-your-tenancy" {
#  value = data.oci_identity_availability_domains.ads.availability_domains
#}
