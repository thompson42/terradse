#!/bin/bash

cd ansible

echo "---- Setting up primary DSE cluster ----"

echo
echo ">>>> Configure recommended OS/Kernel parameters for DSE nodes <<<<"
echo
ansible-playbook -i hosts dse_osparm_change.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Install DSE cluster <<<<"
echo
ansible-playbook -i hosts dse_install.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup DSE cluster Transport Encryption <<<<"
echo
ansible-playbook -i hosts dse_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Activate DSE cluster Unified Authentication <<<<"
echo
ansible-playbook -i hosts dse_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Activate DSE cluster JMX Unified Authentication <<<<"
echo
ansible-playbook -i hosts jmx_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Start DSE cluster... <<<<"
echo
ansible-playbook -i hosts dse_cluster_start.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Configure DSE cluster Authorisation and Roles - DISABLED <<<<"
echo
#ansible-playbook -i hosts dse_authorisation_roles.yml --private-key=~/.ssh/id_rsa_aws
echo

echo "---- Setup seperate Opscenter storage cluster and Opscenter server ----"

echo
echo ">>>> Configure recommended OS/Kernel parameters for OPSC DSECore nodes <<<<"
echo
ansible-playbook -i hosts opsc_osparm_change.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Install OpsCenter server (OPSC_SRV) and separate storage cluster (OPSC DSECore)  <<<<"
echo
ansible-playbook -i hosts opsc_install.yml --private-key=~/.ssh/id_rsa_aws

echo
echo ">>>> Setup Opscenter storage cluster (OPSC DSECore) Authentication <<<<"
echo
ansible-playbook -i hosts opsc_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup Opscenter Server HTTPS and OPSC DSECore Transport Encryption <<<<"
echo
ansible-playbook -i hosts opsc_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Inject Opscenter cluster configuration via API call -> cluster_name.conf <<<<"
echo
ansible-playbook -i hosts opsc_cluster_configure.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup 1) Opscenter Authorisation/Roles and 2) OPSC DSECore Authorisation/Roles - DISABLED <<<<"
echo
#ansible-playbook -i hosts opsc_authorisation_roles.yml --private-key=~/.ssh/id_rsa_aws
echo

echo ">>>> Configure Spark security...  <<<<"

echo
echo ">>>> Stop analyics datacenter <<<<"
echo
ansible-playbook -i hosts spark_datacenter_stop.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup Spark Transport Encryption <<<<"
echo
ansible-playbook -i hosts spark_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Activate Spark Authentication <<<<"
echo
ansible-playbook -i hosts spark_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Start analyics datacenter <<<<"
echo
ansible-playbook -i hosts spark_datacenter_start.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Configure Spark Authorisation and Roles - DISABLED <<<<"
echo
#ansible-playbook -i hosts spark_authorisation_roles.yml --private-key=~/.ssh/id_rsa_aws
echo

cd ..
