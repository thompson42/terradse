#!/bin/bash

cd ansible

echo
echo ">>>> Configure recommended OS/Kernel parameters for DSE nodes <<<<"
echo
ansible-playbook -i hosts dse_osparm_change.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup DSE cluster <<<<"
echo
ansible-playbook -i hosts dse_install.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup DSE cluster Transport Encryption <<<<"
echo
ansible-playbook -i hosts dse_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup DSE cluster Authentication <<<<"
echo
ansible-playbook -i hosts dse_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup DSE cluster Authorisation and Roles <<<<"
echo
ansible-playbook -i hosts dse_authorisation_roles.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Configure recommended OS/Kernel parameters for OPSC DSECore nodes <<<<"
echo
ansible-playbook -i hosts opsc_osparm_change.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup OpsCenter server/separate storage cluster <<<<"
echo
ansible-playbook -i hosts opsc_install.yml --private-key=~/.ssh/id_rsa_aws

echo
echo ">>>> Setup Opscenter server/separate storage cluster Transport Encryption <<<<"
echo
ansible-playbook -i hosts opsc_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup Opscenter server/separate storage cluster Authentication <<<<"
echo
ansible-playbook -i hosts opsc_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup Opscenter server/separate storage cluster Authorisation and Roles <<<<"
echo
ansible-playbook -i hosts opsc_authorisation_roles.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup Spark Transport Encryption and Authentication <<<<"
echo
ansible-playbook -i hosts spark_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup Spark Authentication <<<<"
echo
ansible-playbook -i hosts spark_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup Spark Authorisation and Roles <<<<"
echo
ansible-playbook -i hosts spark_authorisation_roles.yml --private-key=~/.ssh/id_rsa_aws
echo

cd ..
