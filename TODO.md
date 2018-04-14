
## Users and OS accounts:

1. Best Parctise: change from using root accpount to using an SSH key distributed onto each target node.
2. Audit all final file ownership on ansible controller and targets.

## Testing

1. SSL on the OPsC web server will need to be bound to a specific Ip-address (SSL), check what the result of the full run is on the interface var in opscenterd.conf
2. Need to check Vnode allocation on all types (core, search,analytic, graph) in a dry run.
3. Do you need to change the listening port when SSL is enabled on a node? Goes for node->node. cleint-> node, opsc->agent, opsc HTTPS
4. /genansinv_extended.sh: Test properly moves private_ip into public_ip if no public_ip exists
5. /genansinv_extended.sh: Test properly exposes private_dns in hosts file sourced from terraform.tfstate for each node. (used by role: security_create_keystores)
6. Check file ownership on target nodes for keystore.jks and truststore.jks 

## OpscCenter

1. No keyspace will be created by this entire process, OpsC will need to be manually configured to use a keyspace and create a cluster.conf
2. OpsC login account amnd security ?

## Roles

### /ansible/group_vars/all

1. need to shift sensitive passwords to ansible.vault

### /ansible/roles/security_prerequisites

1. need to add new SuperUser and password off ansible.vault
2. need to remove cassandra default SuperUser
3. need to login as super user and perform ALTER security table statements

### /ansible/roles/security_dse_unified_auth_activate

LDAP:

1. Configure selected authentication scheme options: [Link](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secLDAPScheme.html)
2. Adjust the credentials_validity_in_ms and credentials_update_interval_in_ms as required for your environment in the dse.yaml.

JMX

1. Set up JMX authentication to allow nodetool and dsetool operations: [Link](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secEnableJmxAuth.html)

Spark

Beginning in DSE 5.1: Communication between Spark applications and the resource manager are now routed through the CQL native protocol. Enabling client encryption in the cassandra.yaml will also enable encryption for the communication with the DSE Spark Master.

1. Push in a Spark role and user

