#!/bin/bash

# exit on any playbook exception
set -ue

cd ansible

echo "---- Setting up primary DSE cluster ----"
echo ""
echo "---- The system will exit IMMEDIATELY if DSE/Cassandra data directories already exist on the target nodes ! ----"

echo
echo ">>>> Install DSE cluster <<<<"
echo
ansible-playbook dse_install.yml
echo

echo
echo ">>>> Start DSE cluster in insecure mode... <<<<"
echo
ansible-playbook dse_cluster_start.yml
echo

echo
echo ">>>> Configure DSE and SPARK Keyspaces - Strategy / Replication / Repair <<<<"
echo
ansible-playbook dse_keyspace_replication_configure.yml
echo

echo
echo ">>>> Stop DSE cluster... <<<<"
echo
ansible-playbook dse_cluster_stop.yml
echo

echo
echo ">>>> Install DSE security dependencies <<<<"
echo
ansible-playbook dse_security_install_dependencies.yml
echo

echo
echo ">>>> Activate DSE cluster Unified Authentication <<<<"
echo
ansible-playbook dse_authentication.yml
echo

echo ">>>> Configure DSE Role Management <<<<"
echo
ansible-playbook dse_role_management.yml
echo

echo
echo ">>>> Start DSE cluster with Unified Authentication but no Transport Security <<<<"
echo
ansible-playbook dse_cluster_start.yml
echo

echo
echo ">>>> Configure DSE cluster Authorisation and Roles <<<<"
echo
ansible-playbook dse_authorisation_roles.yml
echo

echo
echo ">>>> Stop DSE cluster... <<<<"
echo
ansible-playbook dse_cluster_stop.yml
echo

echo
echo ">>>> Setup DSE cluster Transport Encryption <<<<"
echo
ansible-playbook dse_security.yml
echo

echo
echo ">>>> Activate DSE cluster JMX Unified Authentication <<<<"
echo
ansible-playbook jmx_authentication.yml
echo

echo
echo ">>>> Start DSE cluster... <<<<"
echo
ansible-playbook dse_cluster_start.yml
echo

echo "---- Setup seperate Opscenter storage cluster and Opscenter server ----"

echo
echo ">>>> Install OpsCenter server (OPSC_SRV) and separate storage cluster (OPSC DSECore)  <<<<"
echo
ansible-playbook opsc_install.yml
echo

echo
echo ">>>> Install OPSC security dependencies <<<<"
echo
ansible-playbook opsc_security_install_dependencies.yml
echo

echo
echo ">>>> Setup Opscenter storage cluster (OPSC DSECore) Authentication <<<<"
echo
ansible-playbook opsc_dsecore_authentication.yml
echo

echo
echo ">>>> Start the OPSC DSECore cluster... <<<<"
echo
ansible-playbook opsc_cluster_start.yml
echo

echo
echo ">>>> Setup OPSC DSECore cluster Authorisation/Roles <<<<"
echo
ansible-playbook opsc_dsecore_authorisation_roles.yml
echo

echo
echo ">>>> Setup Opscenter Server HTTPS and OPSC DSECore Transport Encryption <<<<"
echo
ansible-playbook opsc_security.yml
echo

echo
echo ">>>> Setup 1) Opscenter Authorisation/Roles <<<<"
echo
ansible-playbook opsc_authorisation_roles.yml
echo

echo
echo ">>>> Inject Opscenter cluster configuration via API call -> cluster_name.conf <<<<"
echo
ansible-playbook opsc_cluster_configure.yml
echo

echo
echo ">>>> Inject into Opscenter services activation and other best practise configurations via API call <<<<"
echo
ansible-playbook opsc_services_configure.yml
echo

echo
echo ">>>> Inject into Opscenter backup schedule via API call <<<<"
echo " Disabled, must run after schema creation... "
ansible-playbook opsc_backups_configure.yml
echo

echo ">>>> Configure Spark security in datacenter: dse_analytics...  <<<<"

echo
echo ">>>> Stop analyics datacenter <<<<"
echo
ansible-playbook spark_datacenter_stop.yml
echo

echo
echo ">>>> Setup Spark Transport Encryption <<<<"
echo
ansible-playbook spark_security.yml
echo

echo
echo ">>>> Activate Spark Authentication <<<<"
echo
ansible-playbook spark_authentication.yml
echo

echo
echo ">>>> Configure DSEFS, AlwaysOnSQL, Worker cleanup and Logging in the Spark DC <<<<"
echo
ansible-playbook spark_configure.yml
echo

echo
echo ">>>> Start analyics datacenter <<<<"
echo
ansible-playbook spark_datacenter_start.yml
echo

echo
echo ">>>> Configure Search Authorisation and Roles - DISABLED <<<<"
echo
#ansible-playbook search_authorisation_roles.yml
echo

echo
echo ">>>> Configure Spark Authorisation and Roles - DISABLED <<<<"
echo
#ansible-playbook spark_authorisation_roles.yml
echo

echo
echo ">>>> Configure Graph Authorisation and Roles - DISABLED <<<<"
echo
#ansible-playbook graph_authorisation_roles.yml
echo

cd ..
