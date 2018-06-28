#!/bin/bash

# exit on any playbook exception
set -ue

cd ansible

echo "---- Setting up primary DSE cluster ----"

echo
echo ">>>> Install DSE cluster <<<<"
echo
ansible-playbook -i hosts dse_install.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Start DSE cluster in insecure mode... <<<<"
echo
ansible-playbook -i hosts dse_cluster_start.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Configure DSE Security Keyspaces - Strategy and Replication <<<<"
echo
ansible-playbook -i hosts dse_security_keyspaces_configure.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Stop DSE cluster... <<<<"
echo
ansible-playbook -i hosts dse_cluster_stop.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Install DSE security dependencies <<<<"
echo
ansible-playbook -i hosts dse_security_install_dependencies.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Activate DSE cluster Unified Authentication <<<<"
echo
ansible-playbook -i hosts dse_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Start DSE cluster with Unified Authentication but no Transport Security <<<<"
echo
ansible-playbook -i hosts dse_cluster_start.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Configure DSE cluster Authorisation and Roles <<<<"
echo
ansible-playbook -i hosts dse_authorisation_roles.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Stop DSE cluster... <<<<"
echo
ansible-playbook -i hosts dse_cluster_stop.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup DSE cluster Transport Encryption <<<<"
echo
ansible-playbook -i hosts dse_security.yml --private-key=~/.ssh/id_rsa_aws
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

echo "---- Setup seperate Opscenter storage cluster and Opscenter server ----"

echo
echo ">>>> Install OpsCenter server (OPSC_SRV) and separate storage cluster (OPSC DSECore)  <<<<"
echo
ansible-playbook -i hosts opsc_install.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Install OPSC security dependencies <<<<"
echo
ansible-playbook -i hosts opsc_security_install_dependencies.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup Opscenter storage cluster (OPSC DSECore) Authentication <<<<"
echo
ansible-playbook -i hosts opsc_dsecore_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Start the OPSC DSECore cluster... <<<<"
echo
ansible-playbook -i hosts opsc_cluster_start.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup OPSC DSECore cluster Authorisation/Roles <<<<"
echo
ansible-playbook -i hosts opsc_dsecore_authorisation_roles.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup Opscenter Server HTTPS and OPSC DSECore Transport Encryption <<<<"
echo
ansible-playbook -i hosts opsc_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup 1) Opscenter Authorisation/Roles <<<<"
echo
ansible-playbook -i hosts opsc_authorisation_roles.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Inject Opscenter cluster configuration via API call -> cluster_name.conf <<<<"
echo
ansible-playbook -i hosts opsc_cluster_configure.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Inject into Opscenter services activation and other best practise configurations via API call <<<<"
echo " Disabled, must run after schema creation "
#ansible-playbook -i hosts opsc_services_configure.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Inject into Opscenter backup schedule via API call <<<<"
echo " Disabled, must run after schema creation "
#ansible-playbook -i hosts opsc_backups_configure.yml --private-key=~/.ssh/id_rsa_aws
echo

echo ">>>> Configure Spark security in datacenter: dse_analytics...  <<<<"

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
echo ">>>> Configure DSEFS, AlwaysOnSQL, Worker cleanup and Logging in the Spark DC <<<<"
echo
ansible-playbook -i hosts spark_configure.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Start analyics datacenter <<<<"
echo
ansible-playbook -i hosts spark_datacenter_start.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Configure Search Authorisation and Roles - DISABLED <<<<"
echo
#ansible-playbook -i hosts search_authorisation_roles.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Configure Spark Authorisation and Roles - DISABLED <<<<"
echo
#ansible-playbook -i hosts spark_authorisation_roles.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Configure Graph Authorisation and Roles - DISABLED <<<<"
echo
#ansible-playbook -i hosts graph_authorisation_roles.yml --private-key=~/.ssh/id_rsa_aws
echo

cd ..
