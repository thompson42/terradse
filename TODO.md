
# Users and OS accounts:

1. need to chmod all files back to proper owners

# Testing

1. SSL on the OPsC web server will need to be bound to a specific Ip-address (SSL), check what the result of the full run is on the interface var in opscenterd.conf
2. Need to check Vnode allocation on all types (core, search,analytic, graph) in a dry run.
3. Do you need to change the listening port when SSL is enabled on a node? Goes for node->node. cleint-> node, opsc->agent, opsc HTTPS
4. /genansinv_extended.sh: Test properly moves private_ip into public_ip if no public_ip exists

# OpscCenter

1. No keyspace will be created by this entire process, OpsC will need to be manually configured to use a keyspace and create a cluster.conf
2. OpsC login account amnd security ?

# /ansible/group_vars/all

1. need to shift sensitive passwords to ansible.vault

# /ansible/roles/security_prerequisites

1. need to add new SuperUser and password off ansible.vault
2. need to remove cassandra default SuperUser
3. need to login as super user and perform ALTER security table statements

# /ansible/roles/security_create_selfsign_cert: 

1. need to check C, ST, L, O, CN against Datastax selfsign rootCA example: https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secSetUpSSLCert.html
2. need to check params/owner of ssl_certs_path_owner, ssl_certs_path_group
3. should params in security_create_selfsign_cert/defaults be moved to group_vars/all ??

# /ansible/roles/security_create_truststores:

1. keystore_pass needs to be sourced from ansible.vault
2. paths need to be centralised as configureable
3. cert_alias needs to be checked against rootCA example

# /ansible/roles/security_create_keystores:

1. not started

# /ansible/roles/security_dse_unified_auth_activate

## LDAP:

1. Configure selected authentication scheme options: [Link](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secLDAPScheme.html)
2. Adjust the credentials_validity_in_ms and credentials_update_interval_in_ms as required for your environment in the dse.yaml.

## JMX

1. Set up JMX authentication to allow nodetool and dsetool operations: [Link](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secEnableJmxAuth.html)

## Spark

Beginning in DSE 5.1: Communication between Spark applications and the resource manager are now routed through the CQL native protocol. Enabling client encryption in the cassandra.yaml will also enable encryption for the communication with the DSE Spark Master.

1. Push in a Spark role and user

# /playbooks: certificates_install.yml and dse_security.yml

1. Are interdependent, they both need each other to run first,  this have a dependency on { role: security_install } running first ??

