#!/bin/bash

TFSTATE_FILE=/tmp/tfshow_add_node.txt
terraform show terraform_add_node/terraform.tfstate > $TFSTATE_FILE

echo ">>>> Requires a CURRENT 100% ACCURATE ansible/hosts file for the cluster to correctly generate Certificates. <<<<"

if [ $# -lt 2 ]
then
  echo "Error: script has less than 2 arguments:"
  echo "Requires dc_name: the name of the DC you wish to add the node to"
  echo "Requires opsc_server_private_ip: the private ip-address of the OPSC server"
  echo "-- usage: genansinv_add_node.sh [<dc_name>] [<opsc_server_private_ip>]"
  exit 1
fi

DC_NAME="$1"
$opscSrvPrivateIp = "$2"

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

# add a line to the existing hosts file under the target DC section: [<dc_name>]
# test: may be a collection
if [ "${#public_ip[@]}" -eq 0 ]; then
   DSE_LINE_TO_INSERT="${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=${DC_NAME} rack=RAC1 vnode=1 initial_token="
   ADD_NODE_IP_ADDRESS="${private_ip[i]}"
else
   DSE_LINE_TO_INSERT="${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=${DC_NAME} rack=RAC1 vnode=1 initial_token="
   ADD_NODE_IP_ADDRESS="${public_ip[i]}"
fi

MATCH="[${DC_NAME}]"
FILE="ansible/hosts"

sed -i "s/$MATCH/$MATCH\n$DSE_LINE_TO_INSERT/" $FILE

# add a line to the existing hosts file under the [datastax-agent] section
if [ "${#public_ip[@]}" -eq 0 ]; then
   OPSC_LINE_TO_INSERT="${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} opsc_srv_ip=$opscSrvPrivateIp" $DSE_ANSINV_FILE
else
   OPSC_LINE_TO_INSERT="${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} opsc_srv_ip=$opscSrvPrivateIp" $DSE_ANSINV_FILE
fi

MATCH="[datastax_agent]"

sed -i "s/$MATCH/$MATCH\n$OPSC_LINE_TO_INSERT/" $FILE

# replace a section at the end of the hosts file:
#
# [add_node] 
# x.x.x.x 
# [add_node_end]
#
# and call via: - hosts: add_node[0]
#
sed -i "s/\(\[add_node\]\).*\(\[add_node_end\]\)/\1 $ADD_NODE_IP_ADDRESS \2/g" $FILE




