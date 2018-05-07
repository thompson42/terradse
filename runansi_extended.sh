#!/bin/bash

cd ansible

echo
echo ">>>> Configure recommended OS/Kernel parameters for DSE nodes <<<<"
echo
ansible-playbook -i hosts dse_osparm_change.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup DSE application cluster <<<<"
echo
ansible-playbook -i hosts dse_install.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup DSE application cluster transport encryption <<<<"
echo
ansible-playbook -i hosts dse_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup DSE application cluster Unified Authentication <<<<"
echo
ansible-playbook -i hosts dse_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup Spark Encryption and Authentication <<<<"
echo
ansible-playbook -i hosts spark_security.yml --private-key=~/.ssh/id_rsa_aws
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
echo ">>>> Setup Opscenter server/separate storage cluster transport encryption <<<<"
echo
ansible-playbook -i hosts opsc_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup Opscenter server/separate storage cluster transport encryption <<<<"
echo
ansible-playbook -i hosts opsc_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

cd ..
