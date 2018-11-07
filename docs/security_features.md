

# Security and Automation Features

## Testing and TODO

1. Audit all final file ownership on target dse nodes (ctool comparable sys.)

#### Ubuntu 18.04 - pyton pip etc

Need universe added to ubuntu repos:

sudo nano /etc/apt/sources.list

then add  universe at the end of each line, like this:

deb http://archive.ubuntu.com/ubuntu bionic main universe
deb http://archive.ubuntu.com/ubuntu bionic-security main universe 
deb http://archive.ubuntu.com/ubuntu bionic-updates main universe

#### SSL

Need to validate generated root -> intemidiaries -> top level cert order via openssl validate() function, appears to be an incorrect order, current workaround is to force truststore/keystore acceptance.

#### LDAP

Need to test against Windows AD with DSE mixed LDAP/Internal mode.

https://academy.datastax.com/content/datastax-enterprise-46-ldap-support

#### library/dynamic_inventory.py needs to be able to handle the following scenario:

DONE: ANT MOD SLACK

1. create initial cluster: TFSTATE created
2. delete initial cluster: TFSTATE exists but is empty
3. create initial cluster: TFSTATE_LATEST created

The process is now an incorrect state, need to remove TFSTATE if empty so that TFSTATE_LATEST is not created.

function cluster_initlialisation_required() should return None if the original TFSTATE has no children

## HEAP allication

1. See new params in `group_vars/all`: `[heap_xms]` and `[heap_xmx]` - always set them both to the same value to avoid runtime memory allocation issues.

No load systems will need 4GB heaps, development and staging should have 8GB heaps and load testing/production systems should have 20GB heaps.

## Terraform

#### Ports - TODO :x:

AWS Datastax internal security group: need to allow all nodes to communicate on all ports due to AlwaysOnSQL using random ports to connect to other analytic nodes. 
Not allowing this means AlwaysOnSQL service only starts up on the local node.

```
 ingress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    security_groups = ["${aws_security_group.sg_internal_only.id}"]
  }
```

## Ansible Configuration

#### move id_rsa_aws to ansible.cfg

And remove from all bash references e.g. runansi_extended.sh etc.

## Ansible Vault

#### Shift sensitive passwords to ansible vault - TODO :x:

vars: /ansible/group_vars/all

## Primary sanity check and early exit from Ansible process

#### If data exists in the configured DSE data directory exit the entire process ! - COMPLETE :heavy_check_mark:

On Ansible startup via runansi_extended.sh and runansi_add_node.sh if data exists in the configured DSE data directory the entire BASH script will exit. This will protect against overwriting an existing running cluster in the case of creating a new cluster via runansi_extended.sh and will also stop overwriting an existing running node in the case of runansi_add_node.sh

Called by playbooks: dse_install.yml, add_node_install.yml and opsc_install.yml

role: role: dse_test_for_data_directory

## DSE cluster Transport Encryption 

-> playbook: dse_security.yml

#### Generate self signed root certificate for DSE - COMPLETE :heavy_check_mark:

This is the default certificate generation process.

This method generates a self-signed root certificate and then uese that root certificate to sign certificates for each node, each node has a CN that matches it's resolvable FQDN e.g. machine1.mysite.net, machine2.mysite.net

role: security_create_root_certificate

#### CA signed WILDCARD certificate as root certificate *.mysite.net - COMPLETE :heavy_check_mark:

This method takes a CA signed WILDCARD certificate and treats it as a root certificate,  using it to sign individual certificates for each node, each node has a CN that matches it's resolvable FQDN e.g. machine1.mysite.net, machine2.mysite.net

[Setting up SSL certificates](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secSetUpSSLCert.html)

#### CA signed certificates (1x supplied for each node e.g ip-10-0-0-1.mysite.net, ip-10-0-0-2.mysite.net ) - ON HOLD

No requirement as yet for this feature.

This method takes a pre-ordered CA supplied certificate for each node.

#### Create DSE truststores - COMPLETE :heavy_check_mark:

role: security_create_truststores

#### Create DSE keystores - COMPLETE :heavy_check_mark:

role: security_create_keystores

#### Distribute DSE truststores - COMPLETE :heavy_check_mark:

role: security_distribute_truststores

#### Distribute DSE keystores - COMPLETE :heavy_check_mark:

role: security_distribute_keystores

#### Client -> Node - COMPLETE :heavy_check_mark:

[Encrypting Client -> Node SSL](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/encryptClientNodeSSL.html)

role: security_client_to_node

#### Node -> Node - COMPLETE :heavy_check_mark:

[Internode Ecryption](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secInternodeSsl.html)

role: security_node_to_node

#### CQLSH -> Node (local and remote) - COMPLETE :heavy_check_mark:

role: security_client_to_node

## DSE cluster Unified Authentication 

-> playbook: dse_authentication.yml

#### Activate DSE cluster Unified Authentication - COMPLETE :heavy_check_mark:

role: security_auth_activate_internal

## DSE cluster Authorisation and Roles 

-> playbook: dse_authorisation_roles.yml

#### Superuser role replacement via unencrypted driver call - COMPLETE :heavy_check_mark:

Used also by opsc_authorisation_roles.py

role: /ansible/roles/security_cassandra_change_superuser

#### Superuser role replacement via encrypted SSL driver call - ON HOLD

Currently commented out, working on SSL usage of librabry/cassandra_roles.py

Used by dse_authorisation_roles.yml

role: /ansible/roles/security_cassandra_change_superuser 

#### Security table replication - COMPLETE :heavy_check_mark:

role: /ansible/roles/security_keyspaces_configure

## DSE Disk Encryption (TDE)

[Transparent data encryption](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secEncryptEnable.html)

- TODO :x:

## Opscenter Transport Encryption 

-> playbook: opsc_security.yml

#### Create opscenter keystores - COMPLETE :heavy_check_mark:

role: security_opsc_create_keystores

#### Create opscenter truststores - COMPLETE :heavy_check_mark:

role: security_opsc_create_truststores

#### Distribute opscenter truststores - COMPLETE :heavy_check_mark:

role: security_opsc_distribute_truststores

#### Browser -> Opscenter web (HTTPS) - COMPLETE :heavy_check_mark:

[Opscenter Enabling HTTPS](https://docs.datastax.com/en/opscenter/6.1/opsc/configure/opscConfiguringEnablingHttps_t.html)

role: security_opsc_configure

#### Configure seperate opscenter storage cluster - COMPLETE :heavy_check_mark:

role: security_opsc_cluster_configure

#### Configure Opscenter -> Agent encryption at OPSC SERVER level - COMPLETE :heavy_check_mark:

[Enabling SSL/TLS for OpsCenter and Agent communication - Package Installs](https://docs.datastax.com/en/opscenter/6.5/opsc/configure/opscEnableSSLpkg.html)

role: security_opsc_configure

#### Configure Opscenter -> Agent encryption at Agent level - COMPLETE :heavy_check_mark:

[Enabling SSL/TLS for OpsCenter and Agent communication - Package Installs](https://docs.datastax.com/en/opscenter/6.5/opsc/configure/opscEnableSSLpkg.html)

role: security_opc_agent_fetch_keystore
role: security_opc_agent_distribute_keystore
role: security_opc_agent_activate_ssl

#### Configure OPSC SERVER -> DSE encryption and OPSC DSECORE -> DSE encryption - ON HOLD

[Connect to DSE with client-to-node encryption in OpsCenter and the DataStax Agents](https://docs.datastax.com/en/opscenter/6.5/opsc/configure/opscClientToNode.html)

Various roles including: 

1. security_create_keystores
2. security_create_truststores
3. security_opsc_create_keystores
4. security_opsc_create_truststores
5. security_opsc_cluster_configure

## Opscenter Authentication

playbook: opsc_authentication.yml

#### Activate Opscenter internal authentication - COMPLETE :heavy_check_mark:

role: /ansible/roles/security_opsc_configure

#### Activate OPSC DSECore Unified Authentication  - COMPLETE :heavy_check_mark:

role: /ansible/roles/security_auth_activate_internal

## Opscenter Authorisation and Roles

-> playbook: opsc_authorisation_roles.yml

#### Replace Opscenter weak default user - COMPLETE :heavy_check_mark:

role: /ansible/roles/security_opsc_change_admin

#### Replace OPSC DSECore weak superuser - COMPLETE :heavy_check_mark:

role: /ansible/roles/security_change_superuser

## Spark Transport Encryption 

-> playbook: spark_security.yml

[To Activate](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/encryptSparkSSL.html)

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

#### Spark executor -> DSE nodes - COMPLETE :heavy_check_mark:

Client-to-node encryption protects data in flight for the Spark Executor to DSE database connections by establishing a secure channel between the client and the coordinator node.

role: security_client_to_node

#### Client -> AlwaysOnSQL port (DSE 6.0+ only) - TEST :question:

[Enabling SSL for AlwaysOn SQL](https://docs.datastax.com/en/dse/6.0/dse-dev/datastax_enterprise/spark/sslAlwaysOnSql.html)

Uses the same keystore and trustore as client->node and node->node encryption.

role: security_spark_alwaysonsql_configure

## Spark Authentication 

-> playbook: spark_authentication 

#### Activate Spark Authentication - COMPLETE :heavy_check_mark:

role: security_spark_auth_activate

#### Activate AlwaysOnSQL Authentication - TODO :x:

[Using authentication with AlwaysOn SQL](https://docs.datastax.com/en/dse/6.0/dse-dev/datastax_enterprise/spark/authAlwaysOnSql.html)

Shares common role with AlwaysOnSQL transport encryption:

role: security_spark_alwaysonsql_configure

## Spark Authorization and Roles 

-> playbook: spark_authorisation_roles.yml

NOTE: 
1. This playbook is here as a convenience, currently empty it could be used to automate user/role creation.
2. This role is currently commented out in the runansi_extended.sh script

Create a Spark role and user? Limit spark jobs by user?

## Spark Systems Configuration

#### Configure and activate DSEFS on Spark nodes - COMPLETE :heavy_check_mark::

role: spark_dsefs_configure

#### Cleanup Spark worker directory regularly - COMPLETE :heavy_check_mark::

spark-env.sh: spark.worker.ops settings to clear out directory

role: spark_worker_cleanup_configure

#### Configure Spark worker log rolling - COMPLETE :heavy_check_mark::

role: spark_worker_log_rolling_configure

#### Configure AlwaysOnSQL Worker and Executor Cores / RAM etc - COMPLETE :heavy_check_mark::

role: spark_alwaysonsql_configure

## Spark Disk Encryption

#### Spark disk encryption of driver temp files and shuffle files on disk (only available DSE 6.0 onwards) - TODO :x:

[spark.io.encryption.enabled](https://docs.datastax.com/en/dse/6.0/dse-admin/datastax_enterprise/security/encryptSparkConnections.html)

role: security_spark_auth_activate/templates/spark_defaults.conf

## Graph Transport Encryption

-> - COMPLETE :heavy_check_mark:

Enable SSL client-to-node encryption on the DSE Graph node by setting the client_encryption_options.

role: security_client_to_node

## Graph Authentication

-> - COMPLETE :heavy_check_mark:

Allow only authenticated users to access DSE Graph data by enabling DSE Unified Authentication on the transactional database.

role: security_auth_activate_internal

## Graph Authorisation and Roles

-> playbook: graph_authorisation_roles.yml

Limit access to graph data by defining roles for DSE Graph keyspaces and tables, see Managing access to DSE Graph keyspaces.

NOTE: 
1. This playbook is here as a convenience, currently empty it could be used to automate user/role creation.
2. This role is currently commented out in the runansi_extended.sh script

#### Configure credentials in the DSE Graph remote.yaml

[Providing credentials for DSE Graph](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secDSEGraphCred.html)

## Search Transport Encryption

-> - COMPLETE :heavy_check_mark:

Encrypt connections using SSL between HTTP clients and CQL shell to with client-to-node encryption on the DSE Search node.

role: security_client_to_node

## Search Authentication

-> - COMPLETE :heavy_check_mark:

Perform index management tasks with the CQL shell by DSE Unified Authentication.

role: security_auth_activate_internal

## Search Authorisation and Roles

-> playbook: search_authorisation_roles.yml

Use role-based access control (RBAC) for authenticated users to provide search index related permissions.

NOTE: 
1. This playbook is here as a convenience, currently empty it could be used to automate user/role creation.
2. This role is currently commented out in the runansi_extended.sh script


## JMX Transport Encryption

-> playbook: jmx_security.yml - TODO :x:

[Setting up SSL for nodetool, dsetool, and dse advrep](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secureNodetoolSSL.html)
[Securing jConsole SSL](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secureJconsoleSSL.html)

## JMX Unified Authentication 

-> playbook: jmx_authentication.yml

[Enable JMX Authentication](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secEnableJmxAuth.html)
[Support Link](https://support.datastax.com/hc/en-us/articles/204226179-Step-by-step-instructions-for-securing-JMX-authentication-for-nodetool-utility-OpsCenter-and-JConsole)

#### Activate JMX Authentication - COMPLETE :heavy_check_mark:

JMX authenticationis set up in TerraDSE to pass thru to DSE Unified Authentication

[Managing JMX Access Control to MBeans](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secJmxAccessControl.html)

role: /ansible/roles/security_jmx_auth_activate

#### Tools: nodetool, dse, dse client-tool, dsetool, advrep - TEST :x:

Passes -> JMX Authentication -> DSE Unified Authentication

A username / password pair is required once JMX Authentication activated

#### CQLSH and .cqlshrc file creation and distribution - TODO :x:

[CQLSHRC](https://docs.datastax.com/en/dse/5.1/cql/cql/cql_reference/cqlsh_commands/cqlshCqlshrc.html)

1. Needs to be optional with default of false, hardened environments would not accept deployment of credentials on nodes.
2. Need a DSE Unified Authentication account/password stored in clear text in a ~/.cqlshrc file on each node in /home/ec2-user/.cqlshrc
3. Can't be a DSE admin account, needs to be a read-only account?

Better approach to CQLSH/cqlshrc, DSE/.dserc, Spark shell etc is use Datastax Studio for all CQL/Gremlin/SparkSQL

## LDAP Authentication 

- COMPLETE :heavy_check_mark:

[Defining an LDAP scheme](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secLDAPScheme.html)

[Creating roles for LDAP mode](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secRolesLdap.html)

Read the following link if using mixed authentication (e.g. internal AND LDAP/AD authentcation):

"Prevent unintentional role assignment when a group name or user name is found in multiple schemes. When a role has execute permission on a scheme, the role can only be applied to users that authenticated against that scheme."

[Binding a role to an authentication scheme](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/Auth/secGrantScheme.html)

## Audit Logging 

[Enabling data auditing in DataStax Enterprise](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secAuditEnable.html)

[Configuring audit logging](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secAuditConfigLog.html)

[Formats of DataStax Enterprise logs](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secAuditLogFormat.html)

default location for audit log:   /var/log/cassandra/audit/audit.log
default location for logback.xml: /etc/dse/cassandra/logback.xml

In logback.xml we can control log rotation.

role: security_audit_logging_configure - COMPLETE :heavy_check_mark:

## Add a new node to an existing DC within an existing cluster

#### Terraform provision new node via runterra_add_node.sh - TESTING NOW :question:

#### Modify hosts via genansinv_add_node.sh - TESTING NOW :question:

#### Run ansible via runansi_add_node.sh - TODO :x:

Works for initial creation of datacenters, probably doesn't work for adding a new node to a datacenter that has been added later, has no concept of node type for dse_name_2 datacenter name, needs flowing block:

```
solr_enabled=0
spark_enabled=0
graph_enabled=1
auto_bootstrap=0
```

## Bring up a new DC within an existing cluster

- COMPLETE :heavy_check_mark:

This new DC could have various reasons for existing:

1. A duplicate DC type, i.e. a second Spark DC in a cluster with an existing Spark DC (both in the same DC)
2. A new DC type, i.e. a new Graph DC in a cluster with C* and Spark DC's only
3. A backup DC i.e. a new Graph DC in AZ2 in a cluster with an existing Graph DC in AZ1
4. A geographically seperate replicated edge DC 

For STATIC INVENTORY (hosts file):

```
[add_datacenter]
xxx private_ip=xxx private_dns=ip-10-200-175-160.datastax.lan seed=true dc=dse_graph_2 dc_type=dse_graph rack=RAC1 vnode=1 initial_token=
xxx private_ip=xxx private_dns=ip-10-200-175-164.datastax.lan seed=true dc=dse_graph_2 dc_type=dse_graph rack=RAC1 vnode=1 initial_token=
xxx private_ip=xxx private_dns=ip-10-200-175.163.datastax.lan seed=false dc=dse_graph_2 dc_type=dse_graph rack=RAC1 vnode=1 initial_token=

[add_datacenter:vars]
solr_enabled=0
spark_enabled=0
graph_enabled=1
auto_bootstrap=0

```

For DYNAMIC INVENTORY the above configuration will be generated off differences in tfstate_current and tf_state_latest.

## Bring up a replacement node in a specific DC in an existing cluster

Replace a node in a DC. - ON HOLD

## OpsCenter DSE cluster backup automation

NOTE: 

1. Schema automation needs to run prior to backup automation.

-> playbook: opsc_backups_configure.yml

#### Inject DSE cluster backup location into OpsCenter via API call - TESTING NOW :question:

role: /ansible/roles/opsc_backups_configure

#### Inject DSE cluster backup schedule into OpsCenter via API call - TESTING NOW :question:

role: /ansible/roles/opsc_backups_configure

## OpsCenter services automation

-> playbook: opsc_services_configure.yml

#### Activate OpsCenter repair service - TESTING NOW :question:

role: /ansible/roles/opsc_services_configure

## DSE Best Practice configurations and DSE Operations

#### Optimise Linux OS general settings for DSE - COMPLETE :heavy_check_mark:

Recreate file based handler for reload of syscrtl

role: dse_osparam_change

#### Optimise Linux OS SSD settings - COMPLETE :heavy_check_mark:

role: dse_osparam_ssd_change

