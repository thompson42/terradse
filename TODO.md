
## Users and OS accounts:

1. Best Parctise: change from using root account to using an SSH key distributed onto each target node.
2. Audit all final file ownership on ansible controller and targets (ctool comparable sys.)

## Testing

1. SSL on the OPsC web server will need to be bound to a specific Ip-address (SSL), check what the result of the full run is on the interface var in opscenterd.conf
2. Need to check Vnode allocation on all types (core, search,analytic, graph) in a dry run.
3. Do you need to change the listening port when SSL is enabled on a node? Goes for node->node. cleint-> node, opsc->agent, opsc HTTPS
4. /genansinv_extended.sh: Test properly moves private_ip into public_ip if no public_ip exists
5. /genansinv_extended.sh: Test properly exposes private_dns in hosts file sourced from terraform.tfstate for each node. (used by role: security_create_keystores)
6. /genansinv_extended.sh: Test properly indicates new DC names that are now same as block e.g.: [dse_core]
7. /ansible/roles/security_prerequisites - test super user replacement and ALTER on security tables
8. Check file ownership on target nodes for keystore.jks and truststore.jks 

## OpscCenter

Bring a system up and check intial state:

1. OpsC default superuser account replace ?
2. Create and distribute self signed certificates and keystores, truststores for Opsc_Server  - looks like already done, agents too.
3. No keyspace will be created by this entire process, OpsC will need to be manually configured to use a keyspace and create a cluster.conf

## Roles

### /ansible/group_vars/all

1. need to shift sensitive passwords to ansible.vault

### security_node_to_node:

1. reactivate: all

### /ansible/roles/security_prerequisites:

1. need to replicate it to each DC:

hosts file now exposes DC same as a group, need group and count to produce DC:1

ALTER KEYSPACE system_auth WITH REPLICATION = {'class' : 'NetworkTopologyStrategy', 'dc1' : 3, 'dc2' : 2};

### /ansible/roles/security_dse_unified_auth_activate

JMX

1. Set up JMX authentication to allow nodetool and dsetool operations: [Link](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secEnableJmxAuth.html)

Spark

Beginning in DSE 5.1: Communication between Spark applications and the resource manager are now routed through the CQL native protocol. Enabling client encryption in the cassandra.yaml will also enable encryption for the communication with the DSE Spark Master.

1. Create a Spark role and user

LDAP:

1. Configure selected authentication scheme options: [Link](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secLDAPScheme.html)
2. Adjust the credentials_validity_in_ms and credentials_update_interval_in_ms as required for your environment in the dse.yaml.

## Spark transport encryption:

1. https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/encryptSparkSSL.html

## CQL schema

### /ansible/cql_schema_management (playbook):

#### /ansible/roles/create_cql_schema

#### /ansible/roles/modify_cql_schema

## SOLR schema

### /ansible/solr_schema_management (playbook):

#### /ansible/roles/create_solr_schema

#### /ansible/roles/modify_solr_schema

## Graph schema

### /ansible/graph_schema_management (playbook):

#### /ansible/roles/create_graph_schema

#### /ansible/roles/modify_graph_schema

## DSE role management

### /ansible/role_management (playbook):

#### /ansible/roles/create_role

#### /ansible/roles/modify_role






