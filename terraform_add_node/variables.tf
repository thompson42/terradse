#
# The local directory where the SSH key files are stored
#
variable "ssh_key_localpath" {
   default = "/home/alext/.ssh"
}

#
# The local private SSH key file name 
#
variable "ssh_key_filename" {
   default = "id_rsa"
}

#
# AWS EC2 key-pair name
#
variable "keyname" {
   default = "id_rsa"
}

#
# Default AWS region
#
variable "region" {
  default = "us-east-2"
}

#
# Default OS image: Ubuntu
#
variable "ami_id" {
   # Ubuntu Server 16.04 LTS (HVM), SSD Volume Type
   default = "ami-10547475"
}

#
# Environment description
#
variable "env" {
   default = "automation_test"
}

#list the dc name you wish to add the node to
variable "dc_name" {
   default = "dse_analytics"
}

#list the node's count after adding the new node to the dc
variable "final_instance_count" {
   default = "4"
}

#the amazon instance type you wish to use for this additional node
variable "instance_type" {
   default = "t2.2xlarge"
}
