#!/bin/bash

cd ansible

echo "---- Setting up primary DSE cluster ----"

echo
echo ">>>> Install New Node <<<<"
echo
ansible-playbook -i hosts add_node_install.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Install New Node security dependencies <<<<"
echo
ansible-playbook -i hosts add_node_security_install_dependencies.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Activate New Node Unified Authentication <<<<"
echo
ansible-playbook -i hosts add_node_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup New Node Transport Encryption <<<<"
echo
ansible-playbook -i hosts add_node_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Activate New Node JMX Unified Authentication <<<<"
echo
ansible-playbook -i hosts add_node_jmx_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo ">>>> Configure Spark security for New Node <<<<"

echo
echo ">>>> Setup New Node Spark Transport Encryption <<<<"
echo
ansible-playbook -i hosts add_node_spark_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Activate New Node Spark Authentication <<<<"
echo
ansible-playbook -i hosts add_node_spark_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Start Agent on New Node <<<<"
echo
ansible-playbook -i hosts add_node_agents_start.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Start DSE Enterprise on New Node <<<<"
echo
ansible-playbook -i hosts add_node_dse_start.yml --private-key=~/.ssh/id_rsa_aws
echo

cd ..
