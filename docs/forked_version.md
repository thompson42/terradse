## Additional features introduced by this fork

This fork addresses security primarily, the ability to spin up secure DSE environments.

#### Addition of a configurable DSE Security (dse_security.yml) playbook

This playbook concerns itself with security of DSE cluster nodes including required prerequisite table and replication configurations, installation of Python and Java security libraries, a shopping list of security items you want to implement, and a start/stop of DSE on the the nodes at the end to force the changes.

1. See the task: "Install and configure DSE node security to your requirements" indicated by: EDIT LIST and choose the security features you wish to implement, take note of certificate paths.

To run:

```sh
cd ansible
ansible-playbook -i hosts dse_security.yml --private-key=~/.ssh/id_rsa_aws
```

#### Addition of a configurable OpsCenter Security (opsc_security.yml) playbook

This playbook concerns itself with web browser -> OpsCenter server SSL/TLS HTTPS access and OpsCenter server to Agents on DSE nodes.

To run:

```sh
cd ansible
ansible-playbook -i hosts opsc_security.yml --private-key=~/.ssh/id_rsa_aws
```

#### Addition of a configurable Spark Secuirty (spark_security.yml) playbook

This playbook concerns itself with forcing authentication at spark submit level, to block unauthorized access to the Spark service byt calling the role: security_spark_activate, see section 5.7.2 "DSE Unified Authentication and Spark" below.

To run:

```sh
cd ansible
ansible-playbook -i hosts spark_security.yml --private-key=~/.ssh/id_rsa_aws
```

#### Creation of independently runnable Security_xyz encryption roles under ansible/roles to configure:

1. Client -> node encryption: `security_client_to_node`
2. Node -> node encryption: `security__node_to_node`
3. Opscenter HTTPS access: `security_opsc_configure`
4. Agent -> DSE encryption: `security_opsc_agents_xyz`
5. OpsCenter->Agent: `security_opsc_cluster_configure`

#### Introduction of spark and graph DSE datacenter types 

1. Extended versions of terraform file, use: `terraform_extended.sh`
2. Extended versions of `.sh` scripts to handle the new DC types
