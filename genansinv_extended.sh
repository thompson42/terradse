#!/bin/bash

TFSTATE_FILE=/tmp/tfshow.txt
terraform show terraform_extended/terraform.tfstate > $TFSTATE_FILE

if [ $# -lt 1 ]
then
  echo "Error: script has less than 1 arguments, requires number_of_seeds_per_dc"
  echo "-- usage: genansinv_extended.sh [<number_of_seeds_per_dc>]"
  exit 1
fi

DSE_APPCLUSTER_NAME="DseCluster"
DSE_OPSCCLUSTER_NAME="OpscCluster"

dse_nodetype=()
public_ip=()
private_ip=()

# print message to a file (appending)
# $1 - message
# $2 - file to append
pmsg() {
   echo "$1" >> $2
}

usage() {
   echo "Error: [<number_of_seeds_per_dc>] accepts a postive number as the only input parameter"
   echo "-- usage: genansinv_extended.sh [<number_of_seeds_per_dc>]"
}

# check if an input is a positive number
isnum() { 
   awk -v a="$1" 'BEGIN {print ((a == a + 0) && (a > 0)) }'; 
}

while IFS= read -r line
do
   if [[ $line == *"aws_instance"* ]]; then
      typestr="${line#*.}"
      dse_nodetype+=("${typestr%?}")
   fi

   if [[ $line == *"private_ip ="* ]]; then
      private_ip+=("${line#* = }")
   fi

   if [[ $line == *"public_ip ="* ]] && [[ $line =~ "\.[\d]+$" ]]; then
      public_ip+=("${line#* = }")
   fi
done < $TFSTATE_FILE


# Generate an IP list file 
IPLIST_FILE="dse_ec2IpList"
publicIpCnt=${#public_ip[*]}

cat /dev/null > $IPLIST_FILE
for ((i=0; i<${#dse_nodetype[*]}; i++));
do
    # in case there is no public IP available,
    #   we use private IP instead
    if [[ $publicIpCnt == 0 ]]; then
       public_ip[i]=${private_ip[i]}
    fi

    pmsg "${dse_nodetype[i]},${public_ip[i]},${private_ip[i]}" $IPLIST_FILE
done

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

# Generate Ansible inventory file for multi-DC DSE cluster (no OpsCenter)
DSE_ANSINV_FILE="dse_ansHosts"

cat /dev/null > $DSE_ANSINV_FILE
pmsg "[dse:children]" $DSE_ANSINV_FILE
pmsg "dse_core" $DSE_ANSINV_FILE
pmsg "dse_search" $DSE_ANSINV_FILE
pmsg "dse_graph" $DSE_ANSINV_FILE
pmsg "dse_analytics" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE

pmsg "[dse_core]" $DSE_ANSINV_FILE
seedmarked=0
for ((i=0; i<${#dse_nodetype[*]}; i++));
do
   if [[ ${dse_nodetype[i]} == *"dse_core"* ]]; then
      if [[ $seedmarked < $SEED_PER_DC ]]; then
         if [ "${#public_ip[@]}" -eq 0 ]; then
            pmsg "${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=true dc=dse_core rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
            seedmarked=$((seedmarked+1))
         else
            pmsg "${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=true dc=dse_core rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
            seedmarked=$((seedmarked+1))
         fi
      else
         if [ "${#public_ip[@]}" -eq 0 ]; then
             pmsg "${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=dse_core rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         else
             pmsg "${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=dse_core rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         fi
      fi
   fi
done
pmsg "" $DSE_ANSINV_FILE

pmsg "[dse_search]" $DSE_ANSINV_FILE
seedmarked=0
for ((i=0; i<${#dse_nodetype[*]}; i++));
do
   if [[ ${dse_nodetype[i]} == *"dse_search"* ]]; then
      if [[ $seedmarked < $SEED_PER_DC ]]; then
         if [ "${#public_ip[@]}" -eq 0 ]; then
             pmsg "${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=true dc=dse_search rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
             seedmarked=$((seedmarked+1))
         else
             pmsg "${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=true dc=dse_search rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
             seedmarked=$((seedmarked+1))
         fi
      else
         if [ "${#public_ip[@]}" -eq 0 ]; then
             pmsg "${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=dse_search rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         else
             pmsg "${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=dse_search rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         fi
      fi
   fi
done
pmsg "" $DSE_ANSINV_FILE

pmsg "[dse_graph]" $DSE_ANSINV_FILE
seedmarked=0
for ((i=0; i<${#dse_nodetype[*]}; i++));
do
   if [[ ${dse_nodetype[i]} == *"dse_graph"* ]]; then
      if [[ $seedmarked < $SEED_PER_DC ]]; then
         if [ "${#public_ip[@]}" -eq 0 ]; then
             pmsg "${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=true dc=dse_graph rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
             seedmarked=$((seedmarked+1))
         else
             pmsg "${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=true dc=dse_graph rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
             seedmarked=$((seedmarked+1))
         fi
      else
         if [ "${#public_ip[@]}" -eq 0 ]; then
             pmsg "${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=dse_graph rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         else
             pmsg "${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=dse_graph rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         fi
      fi
   fi
done
pmsg "" $DSE_ANSINV_FILE

pmsg "[dse_analytics]" $DSE_ANSINV_FILE
seedmarked=0
for ((i=0; i<${#dse_nodetype[*]}; i++));
do
   if [[ ${dse_nodetype[i]} == *"dse_analytics"* ]]; then
      if [[ $seedmarked < $SEED_PER_DC ]]; then
         if [ "${#public_ip[@]}" -eq 0 ]; then
             pmsg "${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=true dc=dse_analytics rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
             seedmarked=$((seedmarked+1))
         else
             pmsg "${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=true dc=dse_analytics rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
             seedmarked=$((seedmarked+1))
         fi
      else
         if [ "${#public_ip[@]}" -eq 0 ]; then
            pmsg "${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=dse_analytics rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         else
            pmsg "${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=dse_analytics rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         fi
      fi
   fi
done
pmsg "" $DSE_ANSINV_FILE

pmsg "[dse:vars]" $DSE_ANSINV_FILE
pmsg "cluster_name=$DSE_APPCLUSTER_NAME" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "[dse_core:vars]" $DSE_ANSINV_FILE
pmsg "solr_enabled=0" $DSE_ANSINV_FILE
pmsg "spark_enabled=0" $DSE_ANSINV_FILE
pmsg "graph_enabled=0" $DSE_ANSINV_FILE
pmsg "auto_bootstrap=1" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "[dse_search:vars]" $DSE_ANSINV_FILE
pmsg "solr_enabled=1" $DSE_ANSINV_FILE
pmsg "spark_enabled=0" $DSE_ANSINV_FILE
pmsg "graph_enabled=0" $DSE_ANSINV_FILE
pmsg "auto_bootstrap=1" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "[dse_graph:vars]" $DSE_ANSINV_FILE
pmsg "solr_enabled=0" $DSE_ANSINV_FILE
pmsg "spark_enabled=0" $DSE_ANSINV_FILE
pmsg "graph_enabled=1" $DSE_ANSINV_FILE
pmsg "auto_bootstrap=1" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "[dse_analytics:vars]" $DSE_ANSINV_FILE
pmsg "solr_enabled=0" $DSE_ANSINV_FILE
pmsg "spark_enabled=1" $DSE_ANSINV_FILE
pmsg "graph_enabled=0" $DSE_ANSINV_FILE
pmsg "auto_bootstrap=1" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE

#if [ "${#selected_columns[@]}" -eq "${number_of_columns}" ]

pmsg "[opsc_dsecore]" $DSE_ANSINV_FILE
opscsrvmarked=0
seedmarked=0
opscSrvPrivateIP=''
for ((i=0; i<${#dse_nodetype[*]}; i++));
do
   if [[ ${dse_nodetype[i]} == *"dse_opsc"* ]]; then
      # only install OpsCenter server on one host
      if [[ $opscsrvmarked == 0 ]]; then
         if [ "${#public_ip[@]}" -eq 0 ]; then
             opscSrvNodeStr="${private_ip[i]} private_ip=${private_ip[i]}" 
         else
             opscSrvNodeStr="${public_ip[i]} private_ip=${private_ip[i]}" 
         fi
         
         opscSrvPrivateIp="${private_ip[i]}"
         opscsrvmarked=1
      fi

      if [[ $seedmarked < $SEED_PER_DC ]]; then
         if [ "${#public_ip[@]}" -eq 0 ]; then
            pmsg "${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=true dc=DC1 rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
            seedmarked=$((seedmarked+1))
         else
            pmsg "${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=true dc=DC1 rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
            seedmarked=$((seedmarked+1))
         fi
      else
         if [ "${#public_ip[@]}" -eq 0 ]; then
            pmsg "${private_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=DC1 rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         else
            pmsg "${public_ip[i]} private_ip=${private_ip[i]} private_dns=${private_dns[i]} seed=false dc=DC1 rack=RAC1 vnode=1 initial_token=" $DSE_ANSINV_FILE
         fi
      fi
   fi
done
pmsg "" $DSE_ANSINV_FILE

pmsg "[opsc_dsecore:vars]" $DSE_ANSINV_FILE
pmsg "cluster_name=$DSE_OPSCCLUSTER_NAME" $DSE_ANSINV_FILE
pmsg "solr_enabled=0" $DSE_ANSINV_FILE
pmsg "spark_enabled=0" $DSE_ANSINV_FILE
pmsg "graph_enabled=0" $DSE_ANSINV_FILE
pmsg "auto_bootstrap=1" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE

pmsg "[opsc_srv]" $DSE_ANSINV_FILE
pmsg "$opscSrvNodeStr" $DSE_ANSINV_FILE
pmsg "" $DSE_ANSINV_FILE

# Copy the generated ansible inventory file to the proper place
cp $DSE_ANSINV_FILE ./ansible/hosts
