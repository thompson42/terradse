#!/bin/bash

# exit on any playbook exception
set -ue

cd ansible

echo "---- Adding a new Datacenter to an existing DSE cluster ----"
echo ""
echo "---- The system will exit IMMEDIATELY if DSE/Cassandra data directories already exist on the target nodes ! ----"

echo
echo ">>>> Install DSE on new Datacenter nodes <<<<"
echo
ansible-playbook add_datacenter_install.yml
echo

echo
echo ">>>> Install DSE security dependencies on new Datacenter nodes <<<<"
echo
ansible-playbook add_datacenter_security_install_dependencies.yml
echo

echo
echo ">>>> This is a new Datacenter, disable auto_bootstrap !!!!!! <<<< - COMPLETED"
echo
ansible-playbook add_datacenter_disable_auto_bootstrap.yml
echo

echo
echo ">>>> Setup Transport Encryption on new Datacenter nodes <<<<"
echo
ansible-playbook add_datacenter_security.yml
echo

echo ">>>> Configure Spark security on new Datacenter nodes (if required) <<<<"

echo
echo ">>>> Setup Spark Transport Encryption on new Datacenter nodes <<<<"
echo
ansible-playbook add_datacenter_spark_security.yml
echo

echo
echo ">>>> Configure DSEFS, AlwaysOnSQL, Spark Worker cleanup and Logging on new Datacenter nodes TODO: BUG ON DSEFS formatting <<<<"
echo
ansible-playbook add_datacenter_spark_configure.yml
echo

echo
echo ">>>> Start DSE in new Datacenter <<<<"
echo
ansible-playbook add_datacenter_dse_start.yml
echo

echo
echo ">>>> Start Agents in new Datacenter <<<<"
echo
ansible-playbook add_datacenter_agents_start.yml
echo

echo
echo ">>>> Re-Configure DSE and SPARK Keyspaces - Strategy / Replication / Repair <<<<"
echo
ansible-playbook add_datacenter_keyspace_replication_configure.yml
echo

echo
echo ">>>> Start DSE in new Datacenter <<<<"
echo
ansible-playbook add_datacenter_dse_stop.yml
echo

echo
echo ">>>> Activate Unified Authentication on new Datacenter nodes <<<<"
echo
ansible-playbook add_datacenter_authentication.yml
echo

echo
echo ">>>> Activate Unified Authentication on new Datacenter nodes <<<<"
echo
ansible-playbook add_datacenter_role_management.yml
echo

echo
echo ">>>> Activate JMX Unified Authentication on new Datacenter nodes <<<<"
echo
ansible-playbook add_datacenter_jmx_authentication.yml
echo

echo
echo ">>>> Activate Spark Authentication on new Datacenter nodes <<<<"
echo
ansible-playbook add_datacenter_spark_authentication.yml
echo

echo
echo ">>>> Start DSE in new Datacenter <<<<"
echo
ansible-playbook add_datacenter_dse_start.yml
echo




cd ..
