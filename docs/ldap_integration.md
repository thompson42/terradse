
## LDAP and Active Directory integration

#### Mixed Authentication

TerraDSE built clusters are configured to use mixed authentication schemes when using LDAP, INTERNAL accounts like the cassandra superuser still work. This is a good thing, if you ever loose your LDAP server/s you can still authenticate with the INTERNAL accounts.

#### Forced SCHEME EXECUTE PERMISSION

RISK: "Need to prevent unintentional role assignment when a group name or user name is found in multiple schemes."

To prevent accidental role collision TerraDSE we are going to force you in step 4) below to explicitly bind an AUTHENTICATION_METHOD (e.g. LDAP) to a DSE Role.

When a role has execute permission on a scheme(read: AUTHENTICATION_METHOD), the role can only be applied to users that authenticated against that scheme.

#### To use LDAP/AD for 1) User authentication and 2) Role Management:

1. Create Groups in your LDAP/AD environment that you will use in DSE.
2. Add Users to the new Groups in your LDAP/AD environment.
3. Create the identically named Roles in DSE that match the LDAP/AD Groups you created.
4. Bind the LDAP scheme to the new DSE Role: 

```
GRANT EXECUTE on <AUTHENTICATION_METHOD> SCHEME to <ROLE_NAME>
```

5. GRANT SELECT, INSERT etc. rights to your keyspaces and objects in DSE to the new DSE Role.
6. Activate LDAP integration in your ansible/group_vars/my.yml file by setting:


```
my_is_ldap_authentication: true
my_is_ldap_role_management: true
```

7. Configure all other LDAP settings in your ansible/group_vars/my.yml file under the "LDAP Configuration" section
8. Adjust the my_ldap_credentials_validity_in_ms and my_ldap_credentials_update_interval_in_ms as required for your environment
9. Build and run your cluster, login in with your LDAP username/password

#### For more extensive documentation:

[Full Tutorial](https://support.datastax.com/hc/en-us/articles/115005881643-Setting-Up-LDAP-Authentication-and-Authorization-DSE-5-x)

[Defining an LDAP scheme](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secLDAPScheme.html)

[Creating roles for LDAP mode](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secRolesLdap.html)

[Binding a role to an authentication scheme](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/Auth/secGrantScheme.html)
