
## SSL certificates

SSL certificates can be sourced 2 ways:

1. Self signed certificates (for Development, Test, CI, CD and other ephemeral  environments)
2. Trusted CA signed certificates (for Production)

#### To generate and deploy self signed certificates to the ansible host:

Note that is is NOT the distribution phase to target nodes, merely the creation and storage of SSL certificates on the ansible host in a known location. The distribution of SSL certs and keys out into the DSE cluster is taken up by two additional roles: `{ role: security_create_keystores }` and `{ role: security_create_truststores }`

1. Configure default settings for your self signed certificate in: [ansible/roles/security_create_root_certificate/defaults/main.yml](ansible/roles/security_create_root_certificate/defaults/main.yml)

Pay special attention to the params:

```
ssl_certs_path_owner: "cassandra"
ssl_certs_path_group: "cassandra"
```

2. In the `ansible/dse_security.yml` playbook add the following line in the area indicated by: `EDIT LIST`

```
{ role: security_create_root_certificate }
```

This will create a certificate and private key in the following directories on the ansible host (NOT the target nodes):

- `/etc/ssl/{myserver.mydomain.com}/myserver.mydomain.com.key` -> `{myserver.mydomain.com}` is passed in by `{{ansible_fqdn}}`
- `/etc/ssl/{myserver.mydomain.com}/myserver.mydomain.com.pem`

#### To use CA signed WILDCARD certificates:

This method takes a CA signed WILDCARD certificate (e.g. *.prod.mysite.net) and treats it as a root certificate,  using it to sign individual certificates for each node, each node.

See /group_vars/all_example/vars.yml for details on these parameters:

1. Set /group_vars/all/my.yml:{{my_is_self_signed_root_cert}} to false
2. If no DNS resolution in cluster, set /group_vars/all/my.yml:{{my_etc_hosts_file_configure}} to true
3. Configure /group_vars/all/my.yml:{{my_ssl_certs_common_name}} -> prod.mysite.net
4. Configure /group_vars/all/my.yml:{{my_ssl_cluster_name}}
5. Configure /group_vars/all/my.yml:{{my_ssl_certs_organization}}
6. Configure /group_vars/all/my.yml:{{my_ssl_certs_country}}
7. Configure /group_vars/all/my.yml:{{my_ssl_certs_root_directory}}
8. Manually make the directory {{my_ssl_certs_root_directory}}/prod.mysite.net on the ansible host
8. You need two and only two files: e.g prod.mysite.net.pem and prod.mysite.net.key
9. The setting {{my_ssl_certs_common_name}} must match prod.mysite.net
10. IMPORTANT: Your public certificate prod.mysite.net.pem must contain your wildcard certificate then any intermediary certificates in the correct order then your root certificate at the bottom, simply supplying the top level wildcard cetificate to the process will fail.
11. Deploy your CA signed prod.mysite.net.pem and prod.mysite.net.key to directory path {{my_ssl_certs_root_directory}}/{{my_ssl_certs_common_name}} on the ansible host
