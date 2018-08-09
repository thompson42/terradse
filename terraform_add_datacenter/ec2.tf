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
# EC2 instances for DSE cluster, dc_name DC
# 
resource "aws_instance" "${lookup(var.dc_name)}" {
   ami             = "${var.ami_id}"
   instance_type   = "${lookup(var.instance_type)}"
   count           = "1"
   vpc_security_group_ids = ["${aws_security_group.sg_internal_only.id}","${aws_security_group.sg_ssh.id}","${aws_security_group.sg_dse_node.id}"]
   key_name        = "${aws_key_pair.dse_terra_ssh.key_name}"
   associate_public_ip_address = true

   tags {
      Name         = "${lookup(var.dc_name)}-${lookup(var.final_instance_count)}"
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
