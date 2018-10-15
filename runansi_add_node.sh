#!/bin/bash

# exit on any playbook exception
set -ue

cd ansible

echo "---- Adding a new Node to an existing DSE cluster ----"
echo ""
echo "---- The system will exit IMMEDIATELY if DSE/Cassandra data directories already exist on the target node ! ----"

echo
echo ">>>> Install DSE on new Node <<<<"
echo
ansible-playbook add_node_install.yml
echo

echo
echo ">>>> Install DSE security dependencies on new Node <<<<"
echo
ansible-playbook add_node_security_install_dependencies.yml
echo

echo
echo ">>>> Activate DSE cluster Unified Authentication on new Node <<<<"
echo
ansible-playbook add_node_authentication.yml
echo

echo
echo ">>>> Configure DSE Role Management <<<<"
echo
ansible-playbook add_node_role_management.yml
echo

echo
echo ">>>> Setup DSE cluster Transport Encryption on new Node <<<<"
echo
ansible-playbook add_node_security.yml
echo

echo
echo ">>>> Activate JMX Unified Authentication on new Node <<<<"
echo
ansible-playbook add_node_jmx_authentication.yml
echo

echo ">>>> Configure Spark security for new Node (if required) <<<<"

echo
echo ">>>> Setup Spark Transport Encryption on new node <<<<"
echo
ansible-playbook add_node_spark_security.yml
echo

echo
echo ">>>> Activate Spark Authentication on new Node <<<<"
echo
ansible-playbook add_node_spark_authentication.yml
echo

echo
echo ">>>> Configure DSEFS, AlwaysOnSQL, Spark Worker cleanup and Logging on new Node <<<<"
echo
ansible-playbook add_node_spark_configure.yml
echo

echo
echo ">>>> Start DSE on new Node <<<<"
echo
ansible-playbook add_node_dse_start.yml
echo

echo
echo ">>>> Start Agent on new Node <<<<"
echo
ansible-playbook add_node_agents_start.yml
echo

cd ..
