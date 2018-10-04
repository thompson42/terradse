## DSE Unified Authentication

Additional security roles: `security_auth_activate_internal` and `security_install` to implement the core configuration settings for DSE Unified Authentication.

The default SCHEME is `internal`, please re-configure for LDAP and Kerberos SCHEMES, see the documentation here on how to do this:

1. [DSE Unified Authentication](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secAuthAndRbacAbout.html)
2. [Enabling DSE Unified Authentication](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/Auth/secEnableDseAuthenticator.html)

Special note: default install cassandra superuser account:

1. This account needs to be removed and replaced with a new superuser on all exposed installs of DSE, it is there to facilitate initial install and user/role configuration.
2. Automation of this superuser remove/replace is not currently available in this solution, please follow the manual process here: [Replace root account](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/Auth/secCreateRootAccount.html)
3. A possible automation approach is to use this user/role library: [ansible-module-cassandra](https://github.com/Ensighten/ansible-module-cassandra)
4. A candidate role for this process is `roles:security_install`

#### Roles for DSE Unified Authentication

[Creating Roles for Internal Authentication](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secRolesInternal.html)

Once the security_auth_activate_internal role has run you should have a system that challenges user access at all levels, its now time to create your roles and open your system back up, you will need your superuser account to edit these roles. See the above link to create roles, not that you want ot use the "internal" option on that page, with the `SCHEME: internal`  e.g.

```
CREATE ROLE jane WITH LOGIN = true AND PASSWORD = 'Abc123Jane';
```

#### DSE Unified Authentication and Spark Security

Addition of role: `security_spark_auth_activate`

[DSE Analytics security checklist](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secChecklists.html#ariaid-title4)

[Configuring Spark nodes](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/spark/sparkConfiguration.html#sparkConfiguration):

Enabling security and authentication: 

Security is enabled using the `spark_security_enabled` option in `dse.yaml`. Setting it to enabled turns on authentication between the Spark Master and Worker nodes, and allows you to enable encryption. To encrypt Spark connections for all components except the web UI, `enable spark_security_encryption_enabled`. The length of the shared secret used to secure Spark components is set using the `spark_shared_secret_bit_length` option, with a default value of 256 bits. These options are described in DSE Analytics options. For production clusters, enable these authentication and encryption. Doing so does not significantly affect performance.

Authentication and Spark applications:

If authentication is enabled, users need to be authenticated in order to submit an application.
Note: DSE 5.1.4, DSE 5.1.5, and 5.1.6 users should refer to the release notes for information on using Spark SQL applications and DSE authentication.

[Running spark-submit job with internal authentication](https://docs.datastax.com/en/dse/5.1/dse-dev/datastax_enterprise/spark/sparkInternalAuth.html)

[Managing Spark application permissions](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secAuthSpark.html)

