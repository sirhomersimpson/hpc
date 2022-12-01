variable "region" {}
variable "tenancy_ocid" {}
variable "targetCompartment" { default = "ocid1.compartment.oc1..aaaaaaaa2bv45q4vcdc6e4otblyllu4itrsblspvicblqanhwn6q2fhefibq" }
variable "ad" { default = "kWVD:AP-MELBOURNE-1-AD-1" }
variable "ssh_key" { default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHXpznCTs+XPjeUjLPqpH8E0XdWinU25Td/U6t6x2/2iv+zxzKkEeKHEu/mEbIl9tmbUQSLqd/WDLZy8oa/8RbNNqj2VXMjs7AS3stG346E70NDa3Qh2LnP6kMJSbUF1ByijX96MrHH5TiTXknNRbPfENVbssg424So5G0nMfold7cyp519GN4bXrkiEEdN4HcsQ8fEW15/Dk0Mk54RCnVz9cDToRrIQgBCZ1Kbl910Pg24fy7Uh0lHcNynX73JeZlojLXP2cass0U/gSJyYswd+F+nhhRLyv1P4/z+4mg4gtmVmUDh3tNFPFoaLBOy8u0wKGWq10v5p8je8+x1MP9 hpc_canary" }
variable "bastion_shape" { default = "VM.Standard.E4.Flex" }
variable "bastion_instance_ocpus" { default = 2 }
variable "bastion_instance_memgb" { default = 16 }
variable "bastion_username" { default = "opc" }
variable "bastion_image" { default = "ocid1.image.oc1.ap-melbourne-1.aaaaaaaa7onwmilfkqox4q535ggcc3xrknlucgul4hhq22twstghkekhhvnq" }

variable "node_count" { default = 2 } // Min. value is 2
variable "cluster_network" { default = true }
variable "cluster_image" { default = "ocid1.image.oc1.ap-melbourne-1.aaaaaaaa7onwmilfkqox4q535ggcc3xrknlucgul4hhq22twstghkekhhvnq" }
variable "cluster_shape" { default = "BM.HPC2.36" }

# VCN
variable "use_existing_vcn" { default = false }
variable "vcn_subnet" { default = "172.16.0.0/21" }
variable "public_subnet" { default = "172.16.0.0/24" }
variable "private_subnet" { default = "172.16.4.0/22" }
variable "ssh_cidr" { default = "0.0.0.0/0" }
