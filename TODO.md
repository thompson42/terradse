
## Users and OS accounts:

1. Audit all final file ownership on target dse nodes (ctool comparable sys.)

## Testing

1. Need to check Vnode allocation on all types (core, search,analytic, graph) in a dry run.
2. /genansinv_extended.sh: Test properly moves private_ip into public_ip if no public_ip exists
3. /genansinv_extended.sh: Test properly exposes private_dns in hosts file sourced from terraform.tfstate for each node. (used by role: security_dse_create_keystores)
4. /genansinv_extended.sh: Test properly indicates new DC names that are now same as block e.g.: [dse_core]

## convenience shell scripts

### runansi_extended.sh

Currently has experimental Spark authentication

## playbook: opsc_security.yml

### Opscenter Transport Encryption (SSL/TLS)

#### create opscenter keystores - COMPLETE :heavy_check_mark:

role: security_opsc_create_keystores

#### create opscenter truststores - COMPLETE :heavy_check_mark:

role: security_opsc_create_truststores

#### distribute opscenter truststores - COMPLETE :heavy_check_mark:

role: security_opsc_distribute_truststores

#### browser -> opscenter web (HTTPS) - COMPLETE :heavy_check_mark:

[Opscenter enabling HTTPS](https://docs.datastax.com/en/opscenter/6.1/opsc/configure/opscConfiguringEnablingHttps_t.html)

role: security_opsc_configure

#### configure opscenter -> agent encryption - TODO :x:

[OpsCenter enabling SSL](https://docs.datastax.com/en/opscenter/6.0/opsc/configure/opscEnableSSLpkg.html)

"OpsCenter requires the .der file format for SSL. If your existing [agents] ssl_certfile in opscenter.conf is in a .pem format, run the following command to convert the format"

role: security_opsc_configure

#### configure seperate opscenter storage cluster - TODO :x:

1. Run role: /ansible/roles/security_prerequisites for this cluster too.

role: security_opsc_cluster_configure

#### configure opscenter -> dse encryption - COMPLETE :heavy_check_mark:

role: security_opsc_cluster_configure

### Opscenter Authentication - TODO :x:

1. Activate Opscenter authentication
2. Replace Opscenter weak default superuser

## playbook: dse_authentication.yml

### DSE Unified Authentication  - COMPLETE :heavy_check_mark:

role: security_dse_unified_auth_activate

#### Automation - DSE Superuser role and security table replication - IN PROGRESS :bug:

Currently commented out.

This role needs to run prior to client->node encryption activation with the dse cluster up as uses cqlsh

role: /ansible/roles/security_prerequisites

1. need to read hosts file, now exposes DC same as a group, need group and count to produce replication to each DC:
```
ALTER KEYSPACE system_auth WITH REPLICATION = {'class' : 'NetworkTopologyStrategy', 'dc1' : 3, 'dc2' : 2};
```

#### Activating JMX Authentication - TODO :x:

[Support Link](https://support.datastax.com/hc/en-us/articles/204226179-Step-by-step-instructions-for-securing-JMX-authentication-for-nodetool-utility-OpsCenter-and-JConsole)

1. Set up JMX authentication to allow nodetool and dsetool operations: [Enable JMX Authentication](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secEnableJmxAuth.html)
2. This will cause JMX config required for Opscenter

#### LDAP - TODO :x:

1. Configure selected authentication scheme options: [LDAP Schemes](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secLDAPScheme.html)
2. Adjust the credentials_validity_in_ms and credentials_update_interval_in_ms as required for your environment in the dse.yaml.

#### Connecting to DSE Authentication enabled clusters

Covers:

1. dse commands
2. dse client-tool
3. dsetool
4. nodetool
5. jConsole
6. cqlsh
7. kerberos enabled cqlsh
8. DSE graph

[Providing credentials](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secProvideCredentialsTOC.html)

## playbook: dse_security.yml

#### /ansible/group_vars/all - TODO :x:

1. need to shift sensitive passwords to ansible.vault

### Activating DSE Transport Encryption (SSL/TLS)

FACT: For CA signed certs, change the name of the cert fields under "Root certificate" in group_vars/all and run dse_security with security_create_root_certificate
commented out.

[Setting up SSL certificates](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secSetUpSSLCert.html)

#### generate self signed certificates for DSE - COMPLETE :heavy_check_mark:

role: security_dse_create_root_certificate

#### create DSE truststores - COMPLETE :heavy_check_mark:

role: security_dse_create_truststores

#### create DSE keystores - COMPLETE :heavy_check_mark:

role: security_dse_create_keystores

#### distribute DSE truststores - COMPLETE :heavy_check_mark:

role: security_dse_distribute_truststores

#### distribute DSE keystores - COMPLETE :heavy_check_mark:

role: security_dse_distribute_keystores

#### client -> node - COMPLETE :heavy_check_mark:

[Encrypting client -> node SSL](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/encryptClientNodeSSL.html)

role: security_dse_client_to_node

#### node -> node - COMPLETE :heavy_check_mark:

[Internode encryption](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secInternodeSsl.html)

role: security_dse_node_to_node

#### cqlsh -> node (local and remote) - COMPLETE :heavy_check_mark:

FACT: ACCESS DISABLED BY DEFAULT WHEN CLIENT->NODE ENABLED

[To acivate](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/usingCqlshSslAndKerberos.html)

#### jConsole (any client) -> JMX (local and remote) - TODO :x:

1. REMOTE JMX ACCESS DISABLED BY DEFAULT
2. LOCAL ACCESS?

[Securing jConsole SSL](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secureJconsoleSSL.html)

#### nodetool, dse too, dse advrep -> JMX (local and remote) - TODO :x:

1. REMOTE JMX ACCESS DISABLED BY DEFAULT
2. LOCAL ACCESS?

https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secureNodetoolSSL.html

## playbook: spark_security.yml

### Activating Spark Transport Encryption (SSL/TLS)

[to Activate](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/encryptSparkSSL.html)

#### Spark: dse submit  - COMPLETE :heavy_check_mark:

No transport phase.

#### Spark: Spark driver (app) -> DSE - COMPLETE :heavy_check_mark:

Encryption between the Spark driver and DSE is configured by enabling client encryption in cassandra.yaml

role: security_client_to_node

#### Spark: spark master -> worker - COMPLETE :heavy_check_mark:

Encryption between Spark nodes, including between the Spark master and worker, is configured by enabling Spark security in dse.yaml.

role: security_spark_activate

#### Spark: Spark driver (app) -> executors - IN PROGRESS :bug:

Encryption between the Spark driver and executors in client applications is configured by enabling Spark security in the application configuration properties, 
or by default in /etc/dse/spark/spark-defaults.conf

1. Works but small annoying BUG: The regex read/write is duplicating keys in the file on idempotent runs, see:

role: security_spark_activate

#### Spark:  JDBC driver -> Spark SQL Thrift Server - TODO (easy, truststore and keystore already exist) :x:

https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/spark/sslSparkSqlThriftserver.html

#### Spark: browser -> spark UI - COMPLETE :heavy_check_mark:

The Spark web UI by default uses client-to-cluster encryption settings to enable SSL security in the web interface.

### Activating Spark Authentication - TODO :x:

1. Create a Spark role and user?
2. Limit spark jobs by user ?

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






