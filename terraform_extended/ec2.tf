provider "aws" {
   region     = "${var.region}"
}

# 
# SSH key used to access the EC2 instances
#
resource "aws_key_pair" "dse_terra_ssh" {
    key_name = "${var.keyname}"
    public_key = "${file("${var.ssh_key_localpath}/${var.ssh_key_filename}.pub")}"
}

# 
# Security group rules:
# - open SSH port (22) from anywhere
#
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

# 
# Security group rules: 
# - open OpsCenter HTTPS access from anywhere
#   (assuming OpsCenter web access is enabled)
#
resource "aws_security_group" "sg_opsc_web" {
   name = "sg_opsc_web"

   # OpsCenter server HTTPS port
   ingress {
      from_port = 8443
      to_port = 8443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }

   # OpsCenter server HTTP port
   ingress {
      from_port = 8888
      to_port = 8888
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }
}

#
# Security group rules:
# - open opscenter-agent ports
#
resource "aws_security_group" "sg_internal_only" {
   name = "sg_internal_only"
}


#
# Security group rules:
# - Ports required for proper OpsCenter/Datastax-agent function
#
resource "aws_security_group" "sg_opsc_node" {
   name = "sg_opsc_node"

   # Outbound: allow everything to everywhere
   egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # SMTP emal alerting port, non-SSL
   ingress {
      from_port = 25
      to_port = 25
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # SMTP emal alerting port, SSL
   ingress {
      from_port = 465
      to_port = 465
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # SNMP listening port
   ingress {
      from_port = 162
      to_port = 162
      protocol = "udp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # OpsCenter Definitions port
   ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # LCM proxy port
   ingress {
      from_port = 3128
      to_port = 3128
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # Stomp ports: agent -> opsc
   ingress {
      from_port = 61619
      to_port = 61620
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }
}

#
# Security group rules:
# - Ports required for proper DSE function
#
resource "aws_security_group" "sg_dse_node" {
   name = "sg_dse_node"

   # Outbound: allow everything to everywhere
   egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # DSEFS inter-node communication port
   ingress {
      from_port = 5599 
      to_port = 5599
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # DSE inter-node cluster communication port
   # - 7000: No SSL
   # - 7001: With SSL
   ingress {
      from_port = 7000
      to_port = 7001
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # Spark master inter-node communication port
   ingress {
      from_port = 7077
      to_port = 7077
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # JMX monitoring port
   ingress {
      from_port = 7199
      to_port = 7199
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # Port for inter-node messaging service
   ingress {
      from_port = 8609
      to_port = 8609
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # DSE Search web access port
   ingress {
      from_port = 8983
      to_port = 8983
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # Native transport port
   ingress {
      from_port = 9042
      to_port = 9042
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # Native transport port, with SSL
   ingress {
      from_port = 9142
      to_port = 9142
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # Client (Thrift) port
   ingress {
      from_port = 9160
      to_port = 9160
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # Spark SQL Thrift server port
   ingress {
      from_port = 10000
      to_port = 10000
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }

   # Stomp port: opsc -> agent
   ingress {
      from_port = 61621
      to_port = 61621
      protocol = "tcp"
      security_groups = ["${aws_security_group.sg_internal_only.id}"]
   }
}

#
# EC2 instances for DSE OpsCenter, the first of which
# also serves as the bastion host
#
resource "aws_instance" "dse_opsc" {
   ami             = "${var.ami_id}"
   instance_type   = "${lookup(var.instance_type, var.dse_opsc_type)}"
   count           = "${lookup(var.instance_count, var.dse_opsc_type)}"
   vpc_security_group_ids = ["${aws_security_group.sg_internal_only.id}","${aws_security_group.sg_ssh.id}","${aws_security_group.sg_opsc_web.id}","${aws_security_group.sg_opsc_node.id}","${aws_security_group.sg_dse_node.id}"]
   key_name        = "${aws_key_pair.dse_terra_ssh.key_name}"
   associate_public_ip_address = true

   tags {
      Name         = "dse_opsc-${count.index}"
      Environment  = "${var.env}" 
   }

   user_data = "${data.template_file.user_data.rendered}"
}

#
# EC2 instances for DSE cluster, "DSE Core" DC
# 
resource "aws_instance" "dse_core" {
   ami             = "${var.ami_id}"
   instance_type   = "${lookup(var.instance_type, var.dse_core_type)}"
   count           = "${lookup(var.instance_count, var.dse_core_type)}"
   vpc_security_group_ids = ["${aws_security_group.sg_internal_only.id}","${aws_security_group.sg_ssh.id}","${aws_security_group.sg_dse_node.id}"]
   key_name        = "${aws_key_pair.dse_terra_ssh.key_name}"
   associate_public_ip_address = true

   tags {
      Name         = "dse_core-${count.index}"
      Environment  = "${var.env}" 
   }  

   user_data = "${data.template_file.user_data.rendered}"
}

#
# EC2 instances for DSE cluster, "DSE Search" DC
# 
resource "aws_instance" "dse_search" {
   ami             = "${var.ami_id}"
   instance_type   = "${lookup(var.instance_type, var.dse_search_type)}"
   count           = "${lookup(var.instance_count, var.dse_search_type)}"
   vpc_security_group_ids = ["${aws_security_group.sg_internal_only.id}","${aws_security_group.sg_ssh.id}","${aws_security_group.sg_dse_node.id}"]
   key_name        = "${aws_key_pair.dse_terra_ssh.key_name}"
   associate_public_ip_address = true

   tags {
      Name         = "dse_search-${count.index}"
      Environment  = "${var.env}" 
   }  

   user_data = "${data.template_file.user_data.rendered}"
}

#
# EC2 instances for DSE cluster, "DSE Graph" DC
# 
resource "aws_instance" "dse_graph" {
   ami             = "${var.ami_id}"
   instance_type   = "${lookup(var.instance_type, var.dse_graph_type)}"
   count           = "${lookup(var.instance_count, var.dse_graph_type)}"
   vpc_security_group_ids = ["${aws_security_group.sg_internal_only.id}","${aws_security_group.sg_ssh.id}","${aws_security_group.sg_dse_node.id}"]
   key_name        = "${aws_key_pair.dse_terra_ssh.key_name}"
   associate_public_ip_address = true

   tags {
      Name         = "dse_graph-${count.index}"
      Environment  = "${var.env}" 
   }  

   user_data = "${data.template_file.user_data.rendered}"
}

#
# EC2 instances for DSE cluster, "DSE Analytics" DC
# 
resource "aws_instance" "dse_analytics" {
   ami             = "${var.ami_id}"
   instance_type   = "${lookup(var.instance_type, var.dse_analytics_type)}"
   count           = "${lookup(var.instance_count, var.dse_analytics_type)}"
   vpc_security_group_ids = ["${aws_security_group.sg_internal_only.id}","${aws_security_group.sg_ssh.id}","${aws_security_group.sg_dse_node.id}"]
   key_name        = "${aws_key_pair.dse_terra_ssh.key_name}"
   associate_public_ip_address = true

   tags {
      Name         = "dse_analytics-${count.index}"
      Environment  = "${var.env}" 
   }  

   user_data = "${data.template_file.user_data.rendered}"
}

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
