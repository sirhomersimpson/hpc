# Purpose
RMS/TF stack to create a CN configure cluster for Compute HPC. 

The code does the following:
1. Launches a bastion via TF in a public subnet
2. Launches a CN of size N via TF in a private subnet
3. Copies and configure ansible on the bastion
4. Runs ansible to configure the CN nodes for RDMA 

The code can be run on a VM and/or in RMS (preferably)

## Abbreviation/Concepts used in this repo
| Abbreviation | Description                |
|--------------|----------------------------|
| Head node    | Bastion                    | 
| Compute Node | HPC Node                   |
| RMS          | OCI Terraform as a service |

The system design is a bastion in a public subnet that is connected to a bunch of Compute Nodes in a private subnet.
(Check out https://cloudmarketplace.oracle.com/marketplace/content?contentId=128615613)
The bastion is connected to the regular VCN network via the primary NIC. Compute node(s) are connected to the VCN network via the primary NIC 
and as well to the RDMA network via RDMA nics (Mellanox)

# Code documentation
## Terraform 
| Module            | Responsibility                                                                             |
|-------------------|--------------------------------------------------------------------------------------------|
| bastion.tf        | Launches and configures the bastion resource for keys and ansible, it has 4 null resources |
| cluster-network   | Uses instance-pool.tf and instance-pool.configuration.tf to launch a CN of X nodes         |
| network.tf        | Creates the network resources for CN                                                       |
| variables         | data you provided to RMS and TF                                                            |
| data.tf,locals.tf | Regular resource for data and output. output.tf vomits the bastion and compute node ips    |

## Ansible
| Module         | Responsibility                                          |
|----------------|---------------------------------------------------------|
| copy-keys      | copy all ssh keys and config to cluster                 |
| etc-hosts      | populates etc/hosts of cluster in all nodes and bastion |
| hostname       | sets node to hostname with cluster name                 |
| packages       | packages which will be installed for the cluster        |
| rdma-configure | sets up rdma ip                                         |

# Q&A

## How do I zip the directory so I can upload to RMS cleanly ?
Pre: have fully configured config (keys are in Secret Service) 
### oci config 
#### OC1
```
[DEFAULT]
user=ocid1.user.oc1..aaaaaaaar2d2ghpufocaewwh4r7dlayrrhnawikyaxrhp4wwjn4o7kulej2a
fingerprint=d5:a6:ec:b5:43:f6:ef:5b:25:af:c1:c4:e9:b3:e1:49
tenancy=ocid1.tenancy.oc1..aaaaaaaax3q5jcmovrv7qxbops55wzrjeutinobtayaykdasoygtnpko7buq
region=ap-tokyo-1
key_file=/home/rkisnah/.oci/hpc.pem
```

#### R1
```
[DEFAULT]
user=ocid1.user.region1..aaaaaaaaeabbzuneg4xdtwxfc46ciisfubxx2llha6td3g6y6pe64krzbp2a
fingerprint=41:a9:0a:55:2c:28:13:69:4f:e8:4b:c7:b5:5e:ec:14
tenancy=ocid1.tenancy.region1..aaaaaaaa5tiiq4wpo5ywqgwidmh4oz4ipiosyohh3jgvjjswbj4p7cjkkwla
region=r1.oracleiaas.com
key_file=/home/rkisnah/.oci/compute_dev_us_grp-06-10-23-46.pem
```

### Upload to RMS via OCI CLI  
```
### Zip the directory of the TF and put in /tmp for easy upload 
cd /home/rkisnah/src/hpc-ops/oci-hpc-clusternetwork
zip -r /tmp/hpc.zip .
```


## How do I run locally without RMS?
Step 1: Uncomment provider.tf and replace with your setup (Samples: provider.r1-tf, provider.oc1-tf) 
```
provider "oci" {
  tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaax3q5jcmovrv7qxbops55wzrjeutinobtayaykdasoygtnpko7buq"
 ....
}

```
Step 2: Modify terraform.tfvars (Samples: terraform.r1-tfvars, terraform.oc1-tfvars)
```
region            = "ap-melbourne-1"
...
cluster_shape     = "BM.Optimized3.36"
```
Step 3: Run the following commands
```
terraform init
terraform fmt 
terraform validate
terraform plan
terraform apply 
```

**For r1 - you need to do some snowflake settings**
- R1 needs the following environment settings
```
# for R1 Terraform 
export TF_VAR_region=r1
export TF_VAR_cross_connect_location_name=SEA-R1-FAKE-LOCATION
export domain_name_override=oracleiaas.com
export custom_cert_location=~/.oci/combined_r1.crt
```


## Can I change the size of the stack from N and to N+1 or N-1 within a TF Session?
No. This is a limitation of stack. The opensource solution has the same limitation. The reason is that TF code maintains a static view of the infrastructure.

The implications of this is consider, you create a Stack of N nodes:
- If you want to do N-1/N+1, it fails with this error code
```
data.oci_core_instance.cluster_network_instances[0]: Read complete after 1s [id=ocid1.instance.oc1.eu-frankfurt-1.antheljr7rhxvoacgvjbvwmptcvxxbh7zv6zloza4zq2esomek4kv2vbuutq]
Error: Invalid index
  on data.tf line 31, in data "oci_core_instance" "cluster_network_instances"
  31:   instance_id = data.oci_core_cluster_network_instances.cluster_network_instances[0].instances[count.index]["id"]
```
- The option you have - which a big beef from customers, you destroy and re-create with the new N(+/-) nodes

- At one point, I need to think on how to fix this. The solution from the SAE is to have resize from within the cluster via resize.py - https://github.com/oci-hpc/oci-hpc-clusternetwork-dev/tree/master/bin 

## How do I copy locally the cluster keys? 

For OC1, uncomment the following code, in data.tf (In R1 it is fails -> https://dyn.slack.com/archives/CGJN2K4NB/p1656362758166999) 
```
# Debug functions to generate the key to a file
#resource "local_file" "ssh_private_key" {
#  filename = "${path.module}/key.pem"
#  content  = tls_private_key.ssh.private_key_openssh
#}

#resource "local_file" "ssh_public_key" {
#  filename = "${path.module}/pkey.pem"
#  content  = tls_private_key.ssh.public_key_openssh
#}

```

# References
[1] HPC Sales opensource https://github.com/oracle-quickstart/oci-hpc/ https://github.com/oci-hpc/oci-hpc-clusternetwork-dev

[2] RMS Providers supported https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/providers.htm

# Useful cheatsheets
## Run specific resources 
```
terraform apply -target=oci_core_instance.bastion_instance
```
