
## Automate the Launch of AWS Instances for a Secure multi-DC DSE cluster with OpsCenter

The aim of this project is to develop a complete end to end Terraform + Ansible DSE automation system which invokes ALL security capabilities of the DSE platform and ALL best practices of the DSE platform.

This project has a progress document down to ansible role level, please refer to this document to keep up to date on where the system is at: [Security Features](docs/security_features.md)

This project also has a [FAQ](docs/faq.md) page for processes and troubleshooting info.

## Sharp edges

- Please only use Ubuntu 16.04 LTS for now as the target operating system (tested on 16.04.2 and 16.04.5)
- Please use Python 2.7.12 for the ansible host and the Python on each target node
- Please use Ansible 2.4.3.0 or later
- TerraDSE currently targets Datastax Enterprise 5.1.x, 6.0.x and Opscenter 6.5.x, only use these for now.
- TerraDSE needs to run in the sequence defined in runansi_extended.sh, runansi_add_node.sh and runansi_add_datacenter.sh due to dependent steps, please do not edit this process, it's brittle.
- TerraDSE expects to be able to get out of your network to install software from various locations including datastax.com, Ubuntu repos, Java repos and Python repos.
- TerraDSE currently gives you a reasonable level of security but holes do exist, please keep up to date with where we are at with security on the [Security Features](docs/security_features.md) page.
- There is currently no way to allocate a different JVM HEAP size to Opscenter nodes compared to DSE nodes, make sure you have sufficient RAM if running smaller OpsCenter nodes.
- This software is not owned or endorsed by Datastax Inc.
- This software is offered free of charge with no promise of functionality or fitness of purpose and no liability for damages incurred from its use.

## Basic processes: 

The scripts in this repository have 3 major parts:
1. Terraform scripts to launch the required AWS resources (EC2 instances, security groups, etc.) based on the target DSE cluster toplogy.
2. Ansible playbooks to install and configure DSE and OpsCenter on the provisioned AWS EC2 instances.
3. Linux bash scripts to 
   1. generate the ansible host inventory file (required by the ansible playbooks) out of the terraform state output
   2. lauch the terraform scripts and ansible playbooks

## Documentation

| Link  | Summary | State |
| ------------- | ------------- | ------------- |
| [Security and automation features](docs/security_features.md)  | This solution is a work in progress, please refer to the security features document to keep abreast of changes  | WIP |
| [FAQ](docs/faq.md)  | Frequently asked questions  | |
| [Ansible client machine requirements](docs/ansible_requirements.md)  | In order to run this solution your ansible client machine will require the following libraries installed  | Operational |
| [Static ansible inventory](docs/static_inventory.md)  | How to manually manage your Ansible inventory via a hosts .ini file   | Operational |
| [Dynamic ansible inventory](docs/dynamic_inventory.md)  | How to dynamically manage your Ansible inventory via EC2 tags and Terraform state files   | Operational |
| [Create the initial cluster](docs/create_initial_cluster.md)  | Quickstart steps for initial cluster creation  | Operational |
| [Add a new node to existing datacenter](docs/add_node.md)  | Quickstart steps to add a new node to an existing datacenter  | Testing |
| [Add a new datacenter to existing cluster](docs/add_datacenter.md)  | Quickstart steps to add a full datacenter to an existing cluster  | Operational |
| [DSE Unified Authentication](docs/dse_authentication.md)  | Notes on how to use DSE Unified Authentication  | Operational |
| [SSL certificates](docs/ssl_certificates.md)  | Self signed and CA wildcard certificates  | Operational |
| [This fork compared to upstream](docs/forked_version.md)  | Why this fork?  |  |
| [Limitations](docs/limitations.md)  | Limitations of this automation solution  |  |


#### 1. Terraform Introduction and Cluster Topology

Terraform is a great tool to plan, create, and manage infrastructure as code. Through a mechanism called ***providers***, it offers an agonstic way to manage various infrastructure resources (e.g. physical machines, VMs, networks, containers, etc.) from different underlying platforms such as AWS, Azure, OpenStack, and so on. In this respository, I focus on using Terraform to launch AWS resources due to its popularity and 1-year free-tier access. For more information about Terraform itself, please check HashiCorp's document space for Terraform at https://www.terraform.io/docs/.

The infrastructure resources to be lauched is ultimately determined by the target DSE cluster topology. In this repository, a cluster topology like below is used for explanation purpose:
 
![cluster topology](https://github.com/yabinmeng/terradse/blob/master/resources/cluster.topology.png)

By this topology, there are 2 DSE clusters. 
* One cluster is a multi-DC (2 DC in the example) DSE cluster dedicated for application usage.
* Another cluster is a single-DC DSE cluster dedicated for monitoring purpose through DataStax OpsCenter.

Currently, the number of nodes per DC is configurable through Terraform variables. The number of DCs per cluster is fixed at 2 for application cluster and 1 for the monitoring cluster. However, it can be easily expanded to other settings depending on your unique application needs.

The reason of setting up a different monitoring cluster other than the application cluster is to follow the field best practice of physically separating the storage of monitoring metrics data in a different DSE cluster in order to avoid the hardware resource contentions that could happen when manaing the metrics data and application data together. 


#### 2. Use Terraform to Launch Infrastructure Resources

**NOTE:** a linux bash script, ***runterra.sh***, is provided to automate the execution the terraform scripts.

##### 2.1. Pre-requisites

In order to run the terraform script sucessfully, the following procedures need to be executed in advance:

1. Install Terraform software on the computer to run the script
2. Install and configure AWS CLI properly. Make sure you have an AWS account that have the enough privilege to create and configure AWS resources.
3. Create a SSH key-pair. The script automatically uploads the public key to AWS (to create an AWS key pair resource), so the launched AWS EC2 instances can be connected through SSH. The names of the SSH key-pair, by default, should be “id_rsa_aws and id_rsa_aws.pub”. If you choose other names, please make sure to update the Terraform configuration variable accordingly.

#### 2.2. Provision AWS Resources 

##### 2.2.1. EC2 Count and Type

The number and type of AWS EC2 instances are determined at DataCenter (DC) level through terraform variable mappings, with each DC has its own instance type and count as determined by the target DSE cluster topology. The example for the example cluster topology is as below:

```
variable "instance_count" {
   type = "map"
   default = {
      opsc      = 2
      cassandra = 3
      solr      = 3
      spark     = 0
      graph     = 0
   }
}

variable "instance_type" {
   type = "map"
   default = {
      // t2.2xlarge is the minimal DSE requirement
      opsc      = "t2.2xlarge"
      cassandra = "t2.2xlarge"
      solr      = "t2.2xlarge"
      spark     = "t2.2xlarge"
      graph     = "t2.2xlarge"
   }
}
```

When provisioning the required AWS EC2 instances for a specific DC, the type and count is determined through a map search as in the example below:

```
#
## EC2 instances for DSE cluster, "DSE Search" DC
# 
resource "aws_instance" "dse_search" {
   ... ...
   instance_type   = "${lookup(var.instance_type, var.dse_search_type)}"
   count           = "${lookup(var.instance_count, var.dse_search_type)}"
   ... ...
}
```

##### 2.2.2. AWS Key-Pair

The script also creates an AWS key-pair resource that can be associated with the EC2 instances. The AWS key-pair resource is created from a locally generated SSH public key and the corresponding private key can be used to log into the EC2 instances.

```
resource "aws_key_pair" "dse_terra_ssh" {
    key_name = "${var.keyname}"
    public_key = "${file("${var.ssh_key_localpath}/${var.ssh_key_filename}.pub")}"
}

resource "aws_instance" "dse_search" {
   ... ...
   key_name        = "${aws_key_pair.dse_terra_ssh.key_name}"
   ... ... 
}
```

##### 2.2.3. Security Group

In order for the DSE cluster and OpsCenter to work properly, certain ports on the ec2 instances have to be open, as per the following DataStax documents:
* [Securing DataStax Enterprise ports](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secFirewallPorts.html)
* [OpsCenter ports reference](https://docs.datastax.com/en/opscenter/6.1/opsc/reference/opscLcmPorts.html)

The script does so by creating the following AWS security group resources:
1. `sg_ssh`: allows SSH access from public
2. `sg_opsc_web`: allows web Access from public, such as for OpsCenter Web UI
3. `sg_opsc_node`: allows OpsCenter related communication, such as between OpsCenter server and datastax-agent
4. `sg_dse_node`: allows DSE node specific communication

The code snippet below describes how a security group resource is defined and associated with EC2 instances.

```
resource "aws_security_group" "sg_ssh" {
   name = "sg_ssh"

   ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }

   egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
   }
}

... ... // other security group definitions

resource "aws_instance" "dse_search" {
   ... ...
   vpc_security_group_ids = ["${aws_security_group.sg_internal_only.id}","${aws_security_group.sg_ssh.id}","${aws_security_group.sg_dse_node.id}"]
   ... ...
}
```

##### 2.2.4. User Data

One of the key requirements to run DSE cluster is to enable NTP service. The script achieves this through EC2 instance user data. which is provided through a terraform template file. 

```
data "template_file" "user_data" {
   template = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install python-minimal -y
              apt-get install ntp -y
              apt-get install ntpstat -y
              ntpq -pcrv
              EOF
}

resource "aws_instance" "dse_search" {
   ... ...
   user_data = "${data.template_file.user_data.rendered}"
   ... ...
}
```

Other than NTP service, python (minimal version) is also installed in order for Ansible to work properly. Please note that Java, as another essential software required by DSE and OpsCenter software, is currently installed through Ansible and therefore not listed here as part of the User Data installation. 




