# Automate the Launch of AWS Instances for a Secure multi-DC DSE cluster with OpsCenter

The aim of this project is to develop a complete end to end Terraform + Ansible DSE automation system which invokes ALL security capabilities of the DSE platform and ALL best practices of the DSE platform.

This project has a progress document down to ansible role level, please refer to this document to keep up to date on where the system is at: [TODO](TODO.md)

This project also has a [NOTES](NOTES.md) page for processes and troubleshooting info.

# Requires the following python libraries on the Ansible host machine:

1. ruamel.yaml
2. dse-driver
3. pyopenssl

They are listed in the `requirements.txt`, and can be installed via:

```sh
pip -r requirements.txt
```

## Sharp edges:

1. Please only use Ubuntu 16.04 LTS for now as the target operating system (tested on 16.04.2)
2. Please use Python 2.7.12 for the ansible host and the Python on each target node
3. Please use Ansible 2.4.3.0 or later
4. TerraDSE currently targets Datastax Enterprise 5.1.x, 6.0.x and Opscenter 6.5.x, only use these for now.
5. TerraDSE needs to run in the sequence defined in runterra_<action>.sh due to dependent steps, please do not edit this process, it's brittle.
6. TerraDSE expects to be able to get out of your network to install software from various locations including datastax.com, Ubuntu repos, Java repos and Python repos.
7. TerraDSE currently gives you a reasonable level of security but holes do exist, please keep up to date with where we are at with security on the [TODO](TODO.md) page.
8. This software is not owned or endorsed by Datastax Inc.
9. This software is offered free of charge with no promise of functionality or fitness of purpose and no liability for damages incurred from its use.

# Quickstart steps for full cluster creation:

1. Set all params and cluster topology in `terraform_extended/variables.tf`
2. Set all port rules and security in `terraform_extended/ec2.tf`, for AMZN VPC's you will need to modify this file
3. Copy the directory `ansible/group_vars/all_example` to `ansible/group_vars/all` and set paths and vars marked with `[EDIT]` only
4. Change `ansible/group_vars/all/vars.yml` to a symbolic link pointing at `ansible/group_vars/all_example/vars.yml`, you now have default settings for all paramters.
5. Override any default settings in `ansible/group_vars/all_example/vars.yml` by placing the parameter in the `ansible/group_vars/all/my.yml` file with  [my_] in front it.

e.g. if a setting is [dse_repo_email] in `ansible/group_vars/all_example/vars.yml` override it with [my_dse_repo_email] in `ansible/group_vars/all/my.yml`


6. Run `./runterra_extended.sh` and check AWS instances that will be created - accept and run the plan
7. Run `./genansinv_extended.sh` (it will generate the required `/ansible/hosts` file)
8. Run `./runansi_extended.sh` (expects your key to be: `~/.ssh/id_rsa_aws`, edit if necessary)

MUST SEE BELOW for a more full description and more detailed instructions - you will need to set command line arguements to each of the scripts in 6) 7) and 8)

# Quickstart steps to add a node to the above cluster (TERRAFORM PART IN DEVELOPMENT, ANSIBLE PART IN TESTING):

Note: You will need the `ansible/hosts` file from the above cluster creation process to successfully add a node to this cluster due to the fact we have to regenerate keystores in some cases to add the new node's certificate. The hosts file needs to be 100% accurate, do NOT attempt to add a node into this cluster if you are not sure the hosts file is accurate.

1. Make sure you have a hosts file that reflects your target cluster AND a group_vars/all/my.vars that matches the existing nodes in the DC
2. Create your new node
3. Manually insert the node details into your hosts file, use the hosts_add_node_example file as a guide
4. In the hosts file create the [add_node] section and list the node below it
5. For the node listed under [add_node] in the dc= field put the name of the DC you are adding the node to
6. In the hosts file create the [add_node:vars] section with the same contents as in the hosts_add_node_example file
7. In the [add_node:vars] section configure your new node's type; spark, solr etc
8. Override default settings in group_vars/all/vars.yml with a my_ prefix in the group_vars/all/my.yml see group_vars/all_example for examples of how to do this.
9. Make sure all settings in group_vars/all/my.yml are the same as when the cluster was generated.
10. cd to the terraDSE directory and run ./runterra_add_node.sh and monitor Opscenter as the new node comes up.

```
NOTE: A NEW DYNAMIC INVENTORY PROCESS IS CURRENTLY IN DEVELOPMENT, THIS WILL ALLOW YOU TO CONFIGURE EC2 TAGS AND AUTO GENERATE THE ANSIBLE HOSTS FILE OFF THE TERRAFORM .TFSTATE FILE.
```

# Quickstart steps to add a full datacenter to the above cluster (TERRAFORM PART IN DEVELOPMENT, ANSIBLE PART COMPLETE)):

NOTE: Only the ansible functionality works, the Terraform functionality is under a full re-write

1. Make sure you have a hosts file that reflects your target cluster AND a group_vars/all/my.vars that matches the existing nodes in the cluster
2. Create your new nodes
3. Manually insert the node details into your hosts file, use the hosts_add_datacenter_example file as a guide
4. In the hosts file create the [add_datacenter] section and list the nodes below it
5. For the nodes listed under [add_datacenter] in the dc= field put the name of your new DC
6. In the hosts file create the [add_datacenter:vars] section with the same contents as in the hosts_add_datacenter_example file
7. In the [add_datacenter:vars] section configure your new DCs type,\; spark, solr etc
8. Override default settings in group_vars/all/vars.yml with a my_ prefix in the group_vars/all/my.yml see group_vars/all_example for examples of how to do this.
9. Make sure all settings in group_vars/all/my.yml are the same as when the cluster was generated.
10. cd to the terraDSE directory and run ./runterra_add_datacenter.sh and monitor Opscenter as the new DC comes up.

```
NOTE: A NEW DYNAMIC INVENTORY PROCESS IS CURRENTLY IN DEVELOPMENT, THIS WILL ALLOW YOU TO CONFIGURE EC2 TAGS AND AUTO GENERATE THE ANSIBLE HOSTS FILE OFF THE TERRAFORM .TFSTATE FILE.
```

# Basic processes: 

The scripts in this repository have 3 major parts:
1. Terraform scripts to launch the required AWS resources (EC2 instances, security groups, etc.) based on the target DSE cluster toplogy.
2. Ansible playbooks to install and configure DSE and OpsCenter on the provisioned AWS EC2 instances.
3. Linux bash scripts to 
   1. generate the ansible host inventory file (required by the ansible playbooks) out of the terraform state output
   2. lauch the terraform scripts and ansible playbooks

## 1. Terraform Introduction and Cluster Topology

Terraform is a great tool to plan, create, and manage infrastructure as code. Through a mechanism called ***providers***, it offers an agonstic way to manage various infrastructure resources (e.g. physical machines, VMs, networks, containers, etc.) from different underlying platforms such as AWS, Azure, OpenStack, and so on. In this respository, I focus on using Terraform to launch AWS resources due to its popularity and 1-year free-tier access. For more information about Terraform itself, please check HashiCorp's document space for Terraform at https://www.terraform.io/docs/.

The infrastructure resources to be lauched is ultimately determined by the target DSE cluster topology. In this repository, a cluster topology like below is used for explanation purpose:
 
![cluster topology](https://github.com/yabinmeng/terradse/blob/master/resources/cluster.topology.png)

By this topology, there are 2 DSE clusters. 
* One cluster is a multi-DC (2 DC in the example) DSE cluster dedicated for application usage.
* Another cluster is a single-DC DSE cluster dedicated for monitoring purpose through DataStax OpsCenter.

Currently, the number of nodes per DC is configurable through Terraform variables. The number of DCs per cluster is fixed at 2 for application cluster and 1 for the monitoring cluster. However, it can be easily expanded to other settings depending on your unique application needs.

The reason of setting up a different monitoring cluster other than the application cluster is to follow the field best practice of physically separating the storage of monitoring metrics data in a different DSE cluster in order to avoid the hardware resource contentions that could happen when manaing the metrics data and application data together. 


## 2. Use Terraform to Launch Infrastructure Resources

**NOTE:** a linux bash script, ***runterra.sh***, is provided to automate the execution the terraform scripts.

### 2.1. Pre-requisites

In order to run the terraform script sucessfully, the following procedures need to be executed in advance:

1. Install Terraform software on the computer to run the script
2. Install and configure AWS CLI properly. Make sure you have an AWS account that have the enough privilege to create and configure AWS resources.
3. Create a SSH key-pair. The script automatically uploads the public key to AWS (to create an AWS key pair resource), so the launched AWS EC2 instances can be connected through SSH. The names of the SSH key-pair, by default, should be “id_rsa_aws and id_rsa_aws.pub”. If you choose other names, please make sure to update the Terraform configuration variable accordingly.

### 2.2. Provision AWS Resources 

#### 2.2.1. EC2 Count and Type

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
# EC2 instances for DSE cluster, "DSE Search" DC
# 
resource "aws_instance" "dse_search" {
   ... ...
   instance_type   = "${lookup(var.instance_type, var.dse_search_type)}"
   count           = "${lookup(var.instance_count, var.dse_search_type)}"
   ... ...
}
```

#### 2.2.2. AWS Key-Pair

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

#### 2.2.3. Security Group

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

#### 2.2.4. User Data

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

### 2.3. Limitation 

The terraform script presented in this section only focuses on the most fundamental AWS resources for DSE and OpsCenter installation and operation, such as EC2 instances and security groups in particular, For other AWS resources such as VPC, IP Subnet, and so on, we just rely on the default as provided by AWS. But the script should be very easy to extend to include other customized AWS resources.


## 3. Generate Ansible Inventory File Automatically

After the infrastructure instances have been provisioned, we need to install and configure DSE and OpsCenter and these instances accordingly, which is through the Ansible framework that I presented before at [here](https://github.com/yabinmeng/dseansible). One key item in the Ansible framework is the Ansible inventory file which determines key DSE node characteristics such as node IP, seed node, VNode, workload type, and so on. 

Now since we have provisioned the instances using terraform script, it is possible to generate the Ansible inventory file programmatically from terraform output state. Basically the idea is as below:
1. Generate terraform output state in a text file:

  ```sh
  terraform show terraform_extended/terraform.tfstate > $TFSTATE_FILE
  ```

2. Scan the terraform output state text file to generate a file that contains each instance's target DC tag, public IP, and private IP. An example is provided in this repository at: [dse_ec2IpList](https://github.com/thompson42/terradse/blob/master/dse_ec2IpList)

3. The same IP list information can also be used to generate the required Ansible inventory file. In the script, the first node in any DSE DC is automatically picked as the seed node. An example of the generated Ansible inventory file is provided in this repository: [dse_ansHosts](https://github.com/thompson/terradse/blob/master/dse_ansHosts)

A linux script file, ***genansinv_extended.sh***, is providied for this purpose. The script has 3 configurable parameters via input parameters. These parameters will impact the target DSE cluster topology information (as presented in the Ansible inventory file) a bit. Please adjust accordingly for your own case.

1. Script input argument: number of seed nodes per DC, default at 1

  ```sh
  ./genansinv_extended.sh [<number_of_seeds_per_dc>] [<dse_appcluster_name>] [<dse_opsccluster_name>]
  ```
  
2. Script input argument: the name of the application DSE cluster: 

  ```
  "MyAppClusterName"
  ```
3. Script input argument: the name of the OpsCenter monitoring cluster:

  ```
  "MyOpscClusterName"
  ```
  
4. e.g.:

  ```
  ./genansinv_extended.sh 1 dse_appcluster_name dse_opsccluster_name
  ```


## 4. This base forked version features:

1. `dse_install.yml`: installs and configures a multi-DC DSE cluster. This is the same functionality as the previous version.
2. `opsc_install.yml`: installs OpsCenter server, datastax-agents, and configures accordingly to allow proper communication between OpsCenter server and datastax-agents.
3. `osparm_change.yml`: configures OS/Kernel parameters on each node where DSE is installed, as per [Recommended production settings](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/config/configRecommendedSettings.html) from DataStax documentation.

For operational simplicity, a linux script file, ***runansi_extended.sh***, is provided to execute these Ansible playbooks.

## 5. Additional features introduced by this fork

### 5.1 Addition of a configurable DSE Security (dse_security.yml) playbook

This playbook concerns itself with security of DSE cluster nodes including required prerequisite table and replication configurations, installation of Python and Java security libraries, a shopping list of security items you want to implement, and a start/stop of DSE on the the nodes at the end to force the changes.

1. See the task: "Install and configure DSE node security to your requirements" indicated by: EDIT LIST and choose the security features you wish to implement, take note of certificate paths.

To run:

```sh
cd ansible
ansible-playbook -i hosts dse_security.yml --private-key=~/.ssh/id_rsa_aws
```

### 5.2 Addition of a configurable OpsCenter Security (opsc_security.yml) playbook

This playbook concerns itself with web browser -> OpsCenter server SSL/TLS HTTPS access and OpsCenter server to Agents on DSE nodes.

To run:

```sh
cd ansible
ansible-playbook -i hosts opsc_security.yml --private-key=~/.ssh/id_rsa_aws
```

### 5.3 Addition of a configurable Spark Secuirty (spark_security.yml) playbook

This playbook concerns itself with forcing authentication at spark submit level, to block unauthorized access to the Spark service byt calling the role: security_spark_activate, see section 5.7.2 "DSE Unified Authentication and Spark" below.

To run:

```sh
cd ansible
ansible-playbook -i hosts spark_security.yml --private-key=~/.ssh/id_rsa_aws
```

### 5.4 Creation of independently runnable Security_xyz encryption roles under ansible/roles to configure:

1. Client -> node encryption: `security_client_to_node`
2. Node -> node encryption: `security__node_to_node`
3. Opscenter HTTPS access: `security_opsc_configure`
4. Agent -> DSE encryption: `security_opsc_agents_xyz`
5. OpsCenter->Agent: `security_opsc_cluster_configure`

### 5.5 Introduction of spark and graph DSE datacenter types 

1. Extended versions of terraform file, use: `terraform_extended.sh`
2. Extended versions of `.sh` scripts to handle the new DC types


### 5.6 Added `dse_set_heap` role to automate setting HEAP for jvm.options file

1. See new params in `group_vars/all`: `[heap_xms]` and `[heap_xmx]` - always set them both to the same value to avoid runtime memory allocation issues.

### 5.7 DSE Unified Authentication

Additional security roles: `security_unified_auth_activate` and `security_install` to implement the core configuration settings for DSE Unified Authentication.

The default SCHEME is `internal`, please re-configure for LDAP and Kerberos SCHEMES, see the documentation here on how to do this:

1. [DSE Unified Authentication](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secAuthAndRbacAbout.html)
2. [Enabling DSE Unified Authentication](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/Auth/secEnableDseAuthenticator.html)

Special note: default install cassandra superuser account:

1. This account needs to be removed and replaced with a new superuser on all exposed installs of DSE, it is there to facilitate initial install and user/role configuration.
2. Automation of this superuser remove/replace is not currently available in this solution, please follow the manual process here: [Replace root account](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/Auth/secCreateRootAccount.html)
3. A possible automation approach is to use this user/role library: [ansible-module-cassandra](https://github.com/Ensighten/ansible-module-cassandra)
4. A candidate role for this process is `roles:security_install`

### 5.7.1 Roles for DSE Unified Authentication

[Creating Roles for Internal Authentication](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secRolesInternal.html)

Once the security_unified_auth_activate role has run you should have a system that challenges user access at all levels, its now time to create your roles and open your system back up, you will need your superuser account to edit these roles. See the above link to create roles, not that you want ot use the "internal" option on that page, with the `SCHEME: internal`  e.g.

```
CREATE ROLE jane WITH LOGIN = true AND PASSWORD = 'Abc123Jane';
```

### 5.7.2 DSE Unified Authentication and Spark Security

Addition of role: `security_spark_auth_activate`

[DSE Analytics security checklist](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secChecklists.html#ariaid-title4)

[Configuring Spark nodes](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/spark/sparkConfiguration.html#sparkConfiguration):

Enabling security and authentication: 

Security is enabled using the `spark_security_enabled` option in `dse.yaml`. Setting it to enabled turns on authentication between the Spark Master and Worker nodes, and allows you to enable encryption. To encrypt Spark connections for all components except the web UI, `enable spark_security_encryption_enabled`. The length of the shared secret used to secure Spark components is set using the `spark_shared_secret_bit_length` option, with a default value of 256 bits. These options are described in DSE Analytics options. For production clusters, enable these authentication and encryption. Doing so does not significantly affect performance.

Authentication and Spark applications:

If authentication is enabled, users need to be authenticated in order to submit an application.
Note: DSE 5.1.4, DSE 5.1.5, and 5.1.6 users should refer to the release notes for information on using Spark SQL applications and DSE authentication.

[Running spark-submit job with internal authentication](https://docs.datastax.com/en/dse/5.1/dse-dev/datastax_enterprise/spark/sparkInternalAuth.html)

[Managing Spark application permissions](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secAuthSpark.html)

## 6. SSL certificates

SSL certificates can be sourced 2 ways:

1. Self signed certificates (for Development, Test, CI, CD and other ephemeral  environments)
2. Trusted CA signed certificates (for Production)

### 6.1 To generate and deploy self signed certificates to the ansible host:

Note that is is NOT the distribution phase to target nodes, merely the creation and storage of SSL certificates on the ansible host in a known location. The distribution of SSL certs and keys out into the DSE cluster is taken up by two additional roles: `{ role: security_create_keystores }` and `{ role: security_create_truststores }`

1. Configure default settings for your self signed certificate in: [ansible/roles/security_create_root_certificate/defaults/main.yml](ansible/roles/security_create_root_certificate/defaults/main.yml)

Pay special attention to the params:

```
ssl_certs_path_owner: "cassandra"
ssl_certs_path_group: "cassandra"
```

2. In the `ansible/dse_security.yml` playbook add the following line in the area indicated by: `EDIT LIST`

```
{ role: security_create_root_certificate }
```

This will create a certificate and private key in the following directories on the ansible host (NOT the target nodes):

- `/etc/ssl/{myserver.mydomain.com}/myserver.mydomain.com.key` -> `{myserver.mydomain.com}` is passed in by `{{ansible_fqdn}}`
- `/etc/ssl/{myserver.mydomain.com}/myserver.mydomain.com.pem`

### 6.2 To deploy CA signed certificates to the ansible host:

In the case of CA signed certificates you need to go thru the normal process of generating your cetificates and `.csr` files and uploading them to your CA provider.

Once you have the resulting certificate and private key place them in the following directories on the ansible host (NOT the target nodes): 

(or the location you configured in the `ansible/group_vars/all`)

- `/etc/ssl/{myserver.mydomain.com}/myserver.mydomain.com.key`
- `/etc/ssl/{myserver.mydomain.com}/myserver.mydomain.com.pem`












