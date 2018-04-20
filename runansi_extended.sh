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
echo ">>>> Setup DSE Encryption <<<<"
echo
ansible-playbook -i hosts dse_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup DSE Authentication <<<<"
echo
ansible-playbook -i hosts dse_authentication.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup Spark Encryption and Authentication - Experimental <<<<"
echo
ansible-playbook -i hosts spark_security.yml --private-key=~/.ssh/id_rsa_aws
echo

echo
echo ">>>> Setup DSE OpsCenter cluster - DISABLED <<<<"
echo
#ansible-playbook -i hosts opsc_install.yml --private-key=~/.ssh/id_rsa_aws

cd ..
