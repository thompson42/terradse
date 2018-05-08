
## Users and OS accounts:

1. Audit all final file ownership on target dse nodes (ctool comparable sys.)

## Testing

1. Need to check Vnode allocation on all types (core, search,analytic, graph) in a dry run.
2. /genansinv_extended.sh: Test properly moves private_ip into public_ip if no public_ip exists
3. /genansinv_extended.sh: Test properly exposes private_dns in hosts file sourced from terraform.tfstate for each node. (used by role: security_dse_create_keystores)
4. /genansinv_extended.sh: Test properly indicates new DC names that are now same as block e.g.: [dse_core]
5. Client->node should now uncomment truststore correctly allowing Spark thrift server secure access.
6. Need to test opsc_security.yml end to end (may need rolling restarts due to SSL changes?)

#### /ansible/group_vars/all - TODO :x:

1. need to shift sensitive passwords to ansible.vault



### DSE cluster Transport Encryption -> playbook: dse_security.yml

FACT: For CA signed certs, change the name of the cert fields under "Root certificate" in group_vars/all and run dse_security with security_create_root_certificate
commented out.

[Setting up SSL certificates](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secSetUpSSLCert.html)

#### generate self signed certificates for DSE - COMPLETE :heavy_check_mark:

role: security_create_root_certificate

#### create DSE truststores - COMPLETE :heavy_check_mark:

role: security_create_truststores

#### create DSE keystores - COMPLETE :heavy_check_mark:

role: security_create_keystores

#### distribute DSE truststores - COMPLETE :heavy_check_mark:

role: security_distribute_truststores

#### distribute DSE keystores - COMPLETE :heavy_check_mark:

role: security_distribute_keystores

#### client -> node - COMPLETE :heavy_check_mark:

[Encrypting client -> node SSL](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/encryptClientNodeSSL.html)

role: security_client_to_node

#### node -> node - COMPLETE :heavy_check_mark:

[Internode encryption](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secInternodeSsl.html)

role: security_node_to_node

#### cqlsh -> node (local and remote) - COMPLETE :heavy_check_mark:

FACT: ACCESS DISABLED BY DEFAULT WHEN CLIENT->NODE ENABLED

[To acivate](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/usingCqlshSslAndKerberos.html)


### DSE cluster Authentication -> playbook: dse_authentication.yml - COMPLETE :heavy_check_mark:

role: security_unified_auth_activate

### DSE cluster Authorisation and Roles -> playbook: dse_authorisation_roles.yml

#### Superuser role replacement - IN PROGRESS :bug:

Currently commented out, working on SSL usage of librabry/cassandra_roles.py

Used by dse_authorisation_roles.yml and opsc_authorisation_roles.py

role: /ansible/roles/security_change_superuser 

#### Security table replication - TODO :x:

role: /ansible/roles/security_prerequisites

1. need to read hosts file, now exposes DC same as a group, need group and count to produce replication to each DC:
```
ALTER KEYSPACE system_auth WITH REPLICATION = {'class' : 'NetworkTopologyStrategy', 'dc1' : 3, 'dc2' : 2};
```

### Opscenter Transport Encryption -> playbook: opsc_security.yml

#### Create opscenter keystores - COMPLETE :heavy_check_mark:

role: security_opsc_create_keystores

#### Create opscenter truststores - COMPLETE :heavy_check_mark:

role: security_opsc_create_truststores

#### Distribute opscenter truststores - COMPLETE :heavy_check_mark:

role: security_opsc_distribute_truststores

#### Browser -> Opscenter web (HTTPS) - COMPLETE :heavy_check_mark:

[Opscenter enabling HTTPS](https://docs.datastax.com/en/opscenter/6.1/opsc/configure/opscConfiguringEnablingHttps_t.html)

role: security_opsc_configure

#### Configure seperate opscenter storage cluster - COMPLETE :heavy_check_mark:

role: security_opsc_cluster_configure

#### Configure Opscenter -> Agent encryption at OPSC SERVER level - COMPLETE :heavy_check_mark:

[OpsCenter enabling SSL](https://docs.datastax.com/en/opscenter/6.0/opsc/configure/opscEnableSSLpkg.html)

role: security_opsc_configure

#### Configure Opscenter -> Agent encryption at Agent level - TODO :x:

[OpsCenter enabling SSL](https://docs.datastax.com/en/opscenter/6.0/opsc/configure/opscEnableSSLpkg.html)

1. Need AWS environment to develop/test.

role: security_opsc_agents_configure

#### Configure OPSC SERVER -> DSE encryption and OPSC DSECORE -> DSE encryption - TODO :x:

Various roles including: 

1. security_create_keystores
2. security_create_truststores
3. security_opsc_create_keystores
4. security_opsc_create_truststores
5. security_opsc_cluster_configure


### Opscenter Authentication - playbook: opsc_authentication.yml - TODO :x:

1. Activate Opscenter authentication

### Opscenter Authorisation and Roles - playbook: opsc_authorisation_roles.yml - TODO :x:

1. Replace Opscenter weak default superuser
3. Replace OPSC DSECore weak superuser: Run role: /ansible/roles/security_prerequisites for the OPSC DSECore cluster too.


### JMX Authentication - TODO :x:

[Support Link](https://support.datastax.com/hc/en-us/articles/204226179-Step-by-step-instructions-for-securing-JMX-authentication-for-nodetool-utility-OpsCenter-and-JConsole)

1. Set up JMX authentication to allow nodetool and dsetool operations: [Enable JMX Authentication](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secEnableJmxAuth.html)
2. This will cause JMX config required for Opscenter

jConsole (any client) -> JMX (local and remote)

1. REMOTE JMX ACCESS DISABLED BY DEFAULT
2. LOCAL ACCESS?

[Securing jConsole SSL](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secureJconsoleSSL.html)

nodetool, dse too, dse advrep -> JMX (local and remote)

1. REMOTE JMX ACCESS DISABLED BY DEFAULT
2. LOCAL ACCESS?

https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secureNodetoolSSL.html


### LDAP Authentication - TODO :x:

1. Configure selected authentication scheme options: [LDAP Schemes](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secLDAPScheme.html)
2. Adjust the credentials_validity_in_ms and credentials_update_interval_in_ms as required for your environment in the dse.yaml.

### Spark Transport Encryption -> playbook: spark_security.yml

[to Activate](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/encryptSparkSSL.html)

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

#### Client -> AlwaysOnSQL port - TODO :x:

???

### Spark Authentication -> playbook: spark_authentication - COMPLETE :heavy_check_mark:

role: security_spark_auth_activate

### Spark Authorization and Roles -> playbook: spark_authoroisation_roles.yml - TODO :x:

1. Create a Spark role and user?
2. Limit spark jobs by user?

## playbook: solr_security - TODO 

## playbook: graph_security - TODO 

## Nice haves

##  CQL schema managment

### /ansible/cql_schema_management (playbook):

#### /ansible/roles/create_cql_schema

#### /ansible/roles/modify_cql_schema

## SOLR schema management

### /ansible/solr_schema_management (playbook):

#### /ansible/roles/create_solr_schema

#### /ansible/roles/modify_solr_schema

## Graph schema management

### /ansible/graph_schema_management (playbook):

#### /ansible/roles/create_graph_schema

#### /ansible/roles/modify_graph_schema

## DSE role management

### /ansible/role_management (playbook):

#### /ansible/roles/create_role

#### /ansible/roles/modify_role

## Nodetool access

### /ansible/roles/nodetool_command






