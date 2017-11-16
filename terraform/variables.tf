#
# The local directory where the SSH key files are stored
#
variable "ssh_key_localpath" {
   default = "/Users/yabinmeng/.ssh"
}

#
# The local private SSH key file name 
#
variable "ssh_key_filename" {
   default = "id_rsa_aws"
}

#
# AWS EC2 key-pair name
#
variable "keyname" {
   default = "dse-sshkey"
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

#
# DSE workload type string for
# -  "DSE OpsCenter"
# -  "DSE core/Cassandra"
# -  "DSE search/Solr"
# NOTE: make sure the type string matches the "key" string
#       in variable "instance_count/instance_type" map
# 
variable "dse_opsc_type" {
   default = "opsc"
}
variable "dse_core_type" {
   default = "cassandra"
}
variable "dse_search_type" {
   default = "solr"
}

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
