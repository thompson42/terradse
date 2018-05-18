

# Testing

1. Need to check Vnode allocation on all types (core, search,analytic, graph) in a dry run.
2. Audit all final file ownership on target dse nodes (ctool comparable sys.)

# Ansible Vault

#### Shift sensitive passwords to ansible vault

vars: /ansible/group_vars/all - TODO :x:

# DSE cluster Transport Encryption 

-> playbook: dse_security.yml

FACT: For CA signed certs (Not self signed certs), change the name of the cert fields under "Root certificate" in /ansible/group_vars/all and run dse_security with security_create_root_certificate
commented out.

1. [Setting up SSL certificates](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secSetUpSSLCert.html)

#### Generate self signed certificates for DSE - COMPLETE :heavy_check_mark:

role: security_create_root_certificate

#### Create DSE truststores - COMPLETE :heavy_check_mark:

role: security_create_truststores

#### Create DSE keystores - COMPLETE :heavy_check_mark:

role: security_create_keystores

#### Distribute DSE truststores - COMPLETE :heavy_check_mark:

role: security_distribute_truststores

#### Distribute DSE keystores - COMPLETE :heavy_check_mark:

role: security_distribute_keystores

#### Client -> Node - COMPLETE :heavy_check_mark:

1. [Encrypting Client -> Node SSL](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/encryptClientNodeSSL.html)

role: security_client_to_node

#### Node -> Node - COMPLETE :heavy_check_mark:

1. [Internode Ecryption](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secInternodeSsl.html)

role: security_node_to_node

#### CQLSH -> Node (local and remote) - COMPLETE :heavy_check_mark:

FACT: ACCESS DISABLED BY DEFAULT WHEN CLIENT->NODE ENABLED

1. [To Acivate](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/usingCqlshSslAndKerberos.html)


# DSE cluster Unified Authentication 

-> playbook: dse_authentication.yml

#### Activate DSE cluster Unified Authentication - COMPLETE :heavy_check_mark:

role: security_unified_auth_activate

# DSE cluster Authorisation and Roles 

-> playbook: dse_authorisation_roles.yml

#### Superuser role replacement via unencrypted driver call - COMPLETE :heavy_check_mark:

Used also by opsc_authorisation_roles.py

role: /ansible/roles/security_change_superuser

#### Superuser role replacement via encrypted SSL driver call - ON HOLD

Currently commented out, working on SSL usage of librabry/cassandra_roles.py

Used by dse_authorisation_roles.yml

role: /ansible/roles/security_change_superuser 

#### Security table replication - COMPLETE :heavy_check_mark:

role: /ansible/roles/security_prerequisites

1. need to read hosts file, now exposes DC same as a group, need group and count to produce replication to each DC:
```
ALTER KEYSPACE system_auth WITH REPLICATION = {'class' : 'NetworkTopologyStrategy', 'dc1' : 3, 'dc2' : 2};
```
# Opscenter Transport Encryption 

-> playbook: opsc_security.yml

#### Create opscenter keystores - COMPLETE :heavy_check_mark:

role: security_opsc_create_keystores

#### Create opscenter truststores - COMPLETE :heavy_check_mark:

role: security_opsc_create_truststores

#### Distribute opscenter truststores - COMPLETE :heavy_check_mark:

role: security_opsc_distribute_truststores

#### Browser -> Opscenter web (HTTPS) - COMPLETE :heavy_check_mark:

1. [Opscenter Enabling HTTPS](https://docs.datastax.com/en/opscenter/6.1/opsc/configure/opscConfiguringEnablingHttps_t.html)

role: security_opsc_configure

#### Configure seperate opscenter storage cluster - COMPLETE :heavy_check_mark:

role: security_opsc_cluster_configure

#### Configure Opscenter -> Agent encryption at OPSC SERVER level - COMPLETE :heavy_check_mark:

1. [OpsCenter Enabling SSL](https://docs.datastax.com/en/opscenter/6.0/opsc/configure/opscEnableSSLpkg.html)

role: security_opsc_configure

#### Configure Opscenter -> Agent encryption at Agent level - COMPLETE :heavy_check_mark:

role: security_opsc_agents_configure

#### Configure OPSC SERVER -> DSE encryption and OPSC DSECORE -> DSE encryption - ON HOLD

Various roles including: 

1. security_create_keystores
2. security_create_truststores
3. security_opsc_create_keystores
4. security_opsc_create_truststores
5. security_opsc_cluster_configure


# Opscenter Authentication

playbook: opsc_authentication.yml

#### Activate Opscenter internal authentication - COMPLETE :heavy_check_mark:

role: /ansible/roles/security_opsc_configure

#### Activate OPSC DSECore Unified Authentication  - COMPLETE :heavy_check_mark:

role: /ansible/roles/security_unified_auth_activate

# Opscenter Authorisation and Roles

-> playbook: opsc_authorisation_roles.yml

#### Replace Opscenter weak default user - COMPLETE :heavy_check_mark:

role: /ansible/roles/security_opsc_change_admin

#### Replace OPSC DSECore weak superuser - COMPLETE :heavy_check_mark:

role: /ansible/roles/security_change_superuser

# JMX Transport Encryption

-> playbook: jmx_security.yml - TODO :x:

1. [Securing jConsole SSL](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secureJconsoleSSL.html)
2. [Securing NodeTool SSL](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secureNodetoolSSL.html)

# JMX Unified Authentication 

-> playbook: jmx_authentication.yml

1. [Enable JMX Authentication](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secEnableJmxAuth.html)
2. [Support Link](https://support.datastax.com/hc/en-us/articles/204226179-Step-by-step-instructions-for-securing-JMX-authentication-for-nodetool-utility-OpsCenter-and-JConsole)

#### Activate JMX Authentication - COMPLETE :heavy_check_mark:

1. [Managing JMX Access Control to MBeans](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secJmxAccessControl.html)

role: /ansible/roles/security_jmx_auth_activate

### LDAP Authentication - TODO :x:

1. Configure selected authentication scheme options: [LDAP Schemes](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secLDAPScheme.html)
2. Adjust the credentials_validity_in_ms and credentials_update_interval_in_ms as required for your environment in the dse.yaml.

# Spark Transport Encryption 

-> playbook: spark_security.yml

1. [To Activate](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/encryptSparkSSL.html)

#### Browser -> Spark UI - COMPLETE :heavy_check_mark:

The Spark web UI by default uses client-to-cluster encryption settings to enable SSL security in the web interface.

#### dse submit  - COMPLETE :heavy_check_mark:

No transport phase.

#### Spark driver (app) -> DSE - COMPLETE :heavy_check_mark:

Encryption between the Spark driver and DSE is configured by enabling client encryption in cassandra.yaml

role: security_client_to_node

#### Spark master -> worker - COMPLETE :heavy_check_mark:

Encryption between Spark nodes, including between the Spark master and worker, is configured by enabling Spark security in dse.yaml.

role: security_spark_configure

#### Spark driver (app) -> executors - COMPLETE :heavy_check_mark:

Encryption between the Spark driver and executors in client applications is configured by enabling Spark security in the application configuration properties, 
or by default in /etc/dse/spark/spark-defaults.conf

role: security_spark_configure

#### Client -> AlwaysOnSQL port - ON HOLD

Only applicable for DSE 6.0+  - this solution only supports DSE 5.1.x at this point.

# Spark Authentication 

-> playbook: spark_authentication 

#### Activate Spark Authentication - COMPLETE :heavy_check_mark:

role: security_spark_auth_activate

# Spark Authorization and Roles 

-> playbook: spark_authorisation_roles.yml - TODO :x:

1. Create a Spark role and user?
2. Limit spark jobs by user?

TODO:

playbook: solr_security.yml

playbook: graph_security.yml

###  CQL schema managment

-> playbook: cql_schema_management.yml

#### /ansible/roles/create_cql_schema

#### /ansible/roles/modify_cql_schema

### SOLR schema management

-> playbook: solr_schema_management.yml

#### /ansible/roles/create_solr_schema

#### /ansible/roles/modify_solr_schema

### Graph schema management

-> playbook: graph_schema_management.yml

#### /ansible/roles/create_graph_schema

#### /ansible/roles/modify_graph_schema

### Role management

-> playbook: role_management.yml

#### /ansible/roles/create_role

#### /ansible/roles/modify_role

### Nodetool access

-> playbook: nodetool_access.yml

#### /ansible/roles/nodetool_command

# Bringing up a new named DC after original creation where Node->Node encryption is active in the original DC and no outage is acceptable

```
Implementing node -> node encryption - can be done with no downtime and no cluster splitting:

1. Create all certs, .truststores and .keystores and deploy them onto nodes in the old DC
2. On all nodes in the old DC set: internode_encryption: dc
3. Perform a rolling restart of all nodes in the old DC
3. Prepare all the nodes on the new DC with their certs, .truststores and .keystores and set: internode_encryption: all
4. Bring up the new DC

Summary: The old DC will talk to the new DC encrypted. 
And the new DC would talk everywhere encrypted.
```

1. seeds list points to one of the orig DCs
2. cassandra.yaml: autobootstrap=false
3. nodetool rebuild
4. ip-address of opsc_server for new agents
5. need to generate new keystores and truststores for ALL nodes ?







