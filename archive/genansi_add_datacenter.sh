#!/bin/bash

TFSTATE_FILE=/tmp/tfshow_add_node.txt
terraform show terraform_add_datacenter/terraform.tfstate > $TFSTATE_FILE

echo ">>>> Requires a CURRENT 100% ACCURATE ansible/hosts file for the cluster to correctly generate Certificates. <<<<"
echo "---------"
echo "Requires number_of_seeds: the number of seeds for the DC you wish to add"
echo "Requires dc_name: the name of the DC you wish to add"
echo "-- usage: genansinv_add_datacenter.sh [<number_of_seeds>]  [<dc_name>]"

if [ $# -lt 1 ]
then
  echo "Error: script has less than 2 argument:"
  echo "Requires number_of_seeds: the number of seeds for the DC you wish to add"
  echo "Requires dc_name: the name of the DC you wish to add"
  echo "-- usage: genansinv_add_datacenter.sh [<number_of_seeds>]  [<dc_name>]"
  exit 1
fi

NUMBER_OF_SEEDS="$1"
DC_NAME="$2"

public_ip=()
private_ip=()

usage() {
   echo "Error: [<number_of_seeds>] accepts a postive number as the only input parameter"
   echo "-- usage: genansinv_add_datacenter.sh [<number_of_seeds>]  [<dc_name>]"
}

# check if an input is a positive number
isnum() { 
   awk -v a="$NUMBER_OF_SEEDS" 'BEGIN {print ((a == a + 0) && (a > 0)) }'; 
}

while IFS= read -r line
do
   if [[ $line == *"private_ip ="* ]]; then
      private_ip+=("${line#* = }")
   fi

   if [[ $line == *"public_ip ="* ]] && [[ $line =~ "\.[\d]+$" ]]; then
      public_ip+=("${line#* = }")
   fi
done < $TFSTATE_FILE

# default number of seeds per DC is 1
# this can be changed from the only input parameter of this command
SEED_PER_DC=1

if [[ "$1" != "" ]]; then
   res=`isnum "$1"`
   if [[ "$res" != "1" ]] ; then
      usage
      exit 
   fi

   SEED_PER_DC="$1"
fi

# construct the new nodes string
if [ "${#public_ip[@]}" -eq 0 ]; then
   DSE_LINE_TO_INSERT="${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=${DC_NAME} rack=RAC1 vnode=1 initial_token="
   ADD_NODE_IP_ADDRESS="${private_ip[i]}"
else
   DSE_LINE_TO_INSERT="${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=${DC_NAME} rack=RAC1 vnode=1 initial_token="
   ADD_NODE_IP_ADDRESS="${public_ip[i]}"
fi

# replace a section at the end of the hosts file:
#
# [add_node] 
# x.x.x.x ....
# [add_node_end]
#
# and call via: - hosts: add_node[0]
#
sed -i "s/\(\[add_node\]\).*\(\[add_node_end\]\)/\1 $DSE_LINE_TO_INSERT \2/g" .ansible/hosts




