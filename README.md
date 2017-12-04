# Automate the Launch of AWS Instances for a multi-DC DSE cluster with OpsCenter

Previously I came up with a framework (https://github.com/yabinmeng/dseansible) to automate the creation of a multi-DC DSE cluster using Ansible playbook. That framework however doesn't provision the underlying infrastcture and it relies on the  number of the node instances required by the DSE cluster topology to be in place in advance.

In this repository, I will add the missing part to automate provisioning the required hardware infrastructure on AWS using HashiCorp's terraform script. The type and number of AWS EC2 instances are determined by th target DSE cluster topology. 

The scripts in this repository have 3 major parts:
1. Terraform scripts to launch the required AWS resources (EC2 instances, security groups, etc.) based on the target DSE cluster toplogy.
2. Ansible playbooks to install and configure DSE and OpsCenter on the provisioned AWS EC2 instances.
3. Linux bash scripts to 
   1. generate the ansible host inventory file (required by the ansible playbooks) out of the terraform state output
   2. lauch the terraform scripts and ansible playbooks

Among them, the ansible part follows exactly the same framework as in my previous repository. Please check that repository for more details. In this repository, I will focus mainly on the remaining two parts and touch a bit on the ansible part with the new playbook that wasn't in the previous repository.


## Terraform Introduction and Cluster Topology

Terraform is a great tool to plan, create, and manage infrastructure as code. Through a mechanism called ***providers***, it offers an agonstic way to manage various infrastructure resources (e.g. physical machines, VMs, networks, containers, etc.) from different underlying platforms such as AWS, Azure, OpenStack, and so on. In this respository, I focus on using Terraform to launch AWS resources due to its popularity and 1-year free-tier access. For more information about Terraform itself, please check HashiCorp's document space for Terraform at https://www.terraform.io/docs/.

The infrastructure resources to be lauched is ultimately determined by the target DSE cluster topology. In this repository, a cluster topology like below is used for explanation purpose:
 
![cluster topology](https://github.com/yabinmeng/terradse/blob/master/resources/cluster.topology.png)

By this topology, there are 2 DSE clusters. 
* One cluster is a multi-DC (2 DC in the example) DSE cluster dedicated for application usage.
* Another cluster is a single-DC DSE cluster dedicated for monitoring purpose through DataStax OpsCenter.

Currently, the number of nodes per DC is configurable through Terraform variables. The number of DCs per cluster is fixed at 2 for application cluster and 1 for the monitoring cluster. However, it can be easily expanded to other settings depending on your unique application needs.

The reason of setting up a different monitoring cluster other than the application cluster is to follow the field best practice of physically separating the storage of monitoring metrics data in a different DSE cluster in order to avoid the hardware resource contentions that could happen when manaing the metrics data and application data together. 


## Use Terraform to Launch Infrastructure Resources

### Pre-requisites

In order to run the terraform script sucessfully, the following procedures need to be executed in advance:

1. Install Terraform software on the computer to run the script
2. Install and configure AWS CLI properly. Make sure you have an AWS account that have the enough privilege to create and configure AWS resources.
3. Create a SSH key-pair. The script automatically uploads the public key to AWS (to create an AWS key pair resource), so the launched AWS EC2 instances can be connected through SSH. The names of the SSH key-pair, by default, should be “id_rsa_aws and id_rsa_aws.pub”. If you choose other names, please make sure to update the Terraform configuration variable accordingly.

### Define AWS EC2 Count and Type

The number and type of AWS EC2 instances are determined at DataCenter (DC) level through terraform variable mappings, with each DC has its own instance type and count as determined by the target DSE cluster topology. The example for the example cluster topology is as below:
```
variable "instance_count" {
   type = "map"
   default = {
      opsc      = 2
      cassandra = 3
      solr      = 3
   }
}

variable "instance_type" {
   type = "map"
   default = {
      // t2.2xlarge is the minimal DSE requirement
      opsc      = "t2.2xlarge"
      cassandra = "t2.2xlarge"
      solr      = "t2.2xlarge"
   }
}
```

When provisioning the required AWS EC2 instances for a specific DC, the type and count is determined through a map search as in the example below:
```
#
# EC2 instances for DSE cluster, "DSE Search" DC
# 
resource "aws_instance" "dse_search" {
   ... ...
   instance_type   = "${lookup(var.instance_type, var.dse_search_type)}"
   count           = "${lookup(var.instance_count, var.dse_search_type)}"
   ... ...
}
```

### AWS Resources: Security Group and EC2 User Data  

In order for the DSE cluster and OpsCenter to work properly, certain ports on the ec2 instances have to be open, as per the following DataStax documents:
* ![Securing DataStax Enterprise ports](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secFirewallPorts.html)
* ![OpsCenter ports reference](https://docs.datastax.com/en/opscenter/6.1/opsc/reference/opscLcmPorts.html)

The script does so by creating the following AWS security group resources:
1. sg_ssh: allows SSH access from public
2. sg_opsc_web: allows OpsCenter Web Access from public
3. sg_opsc_node: allows communication between OpsCenter and datastax-agent
4. sg_dse_node: allow communication between DSE nodes
