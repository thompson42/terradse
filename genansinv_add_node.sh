#!/bin/bash

TFSTATE_FILE=/tmp/tfshow_add_node.txt
terraform show terraform_add_node/terraform.tfstate > $TFSTATE_FILE

echo ">>>> Requires a CURRENT 100% ACCURATE ansible/hosts file for the cluster to correctly generate Certificates. <<<<"
echo "---------"
echo "Requires dc_name: the name of the DC you wish to add the node to"
echo "-- usage: genansinv_add_node.sh [<dc_name>]"

if [ $# -lt 1 ]
then
  echo "Error: script has less than 1 argument:"
  echo "Requires dc_name: the name of the DC you wish to add the node to"
  echo "-- usage: genansinv_add_node.sh [<dc_name>]"
  exit 1
fi

DC_NAME="$1"

public_ip=()
private_ip=()

while IFS= read -r line
do
   if [[ $line == *"private_ip ="* ]]; then
      private_ip+=("${line#* = }")
   fi

   if [[ $line == *"public_ip ="* ]] && [[ $line =~ "\.[\d]+$" ]]; then
      public_ip+=("${line#* = }")
   fi
done < $TFSTATE_FILE

# construct the new nodes string
if [ "${#public_ip[@]}" -eq 0 ]; then
   DSE_LINE_TO_INSERT="${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=${DC_NAME} rack=RAC1 vnode=1 initial_token="
   ADD_NODE_IP_ADDRESS="${private_ip[i]}"
else
   DSE_LINE_TO_INSERT="${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=${DC_NAME} rack=RAC1 vnode=1 initial_token="
   ADD_NODE_IP_ADDRESS="${public_ip[i]}"
fi

# insert a section at the end of the hosts file:
#
# [add_node] 
# x.x.x.x ....

# and call via: - hosts: add_node[0]
#
sed -e "\$a[add_node_end]"
sed -e "\$a$DSE_LINE_TO_INSERT" .ansible/hosts




