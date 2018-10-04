
## LDAP and Active Directory integration

#### To use LDAP/AD for LDAP Users and DSE Roles, basic outline:

1. Create DSE Groups in your LDAP/AD server or re-use existing LDAP/AD Group names
2. Create the identically named Roles in DSE that match the LDAP/AD Group
3. Bind the LDAP scheme to the new DSE Role
4. Assign rights to keyspaces, rights to objects in DSE to the new DSE Role
5. Activate LDAP integration in your ansible/group_vars/my.yml file by setting:

```
my_is_ldap_authentication: true
my_is_ldap_role_management: true
```
6. Configure all other LDAP settings in your ansible/group_vars/my.yml file under the "LDAP Configuration" section
7. Adjust the my_ldap_credentials_validity_in_ms and my_ldap_credentials_update_interval_in_ms as required for your environment
8. Build and run your cluster, login in with your LDAP username/password

#### For more extensive documentation:

[Defining an LDAP scheme](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secLDAPScheme.html)

[Creating roles for LDAP mode](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secRolesLdap.html)

Read the following link if using mixed authentication (e.g. internal AND LDAP/AD authentcation):

"Prevent unintentional role assignment when a group name or user name is found in multiple schemes. When a role has execute permission on a scheme, the role can only be applied to users that authenticated against that scheme."

[Binding a role to an authentication scheme](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/Auth/secGrantScheme.html)
