#!/usr/bin/python
# -*- coding: utf-8 -*-

# Deprecated in favour of cassandra_topology_replication.py
# Rather than take a dict of datacenter names, dynamically discover them via the drivers cluster metadata
# In the new cassandra_topology_replication.py

DOCUMENTATION = '''
---
module: cassandra_security_replication

short_description: Manage Cassandra Security Keyspace Replication
description:
    - Security Keysapce Replication
    - requires `pip install cassandra-driver`
    - Related Docs: https://datastax.github.io/python-driver/api/cassandra/query.html
    - Related Docs: https://docs.datastax.com/en/cql/3.3/cql/cql_reference/create_role.html
author: "Alex Thompson"
options:
  keyspace_name:
    description:
      - name of the keyspace to ALTER, either DSE_SECURITY or SYSTEM_AUTH
    required: true
  replication_class:
    description:
      - replication_class; usually NetworkTopologyStrategy
    required: true
  replication_dc:
    description:
      - a dictionary of dc_name:node_count pairs to construct the replication_factor from
    required: true
  is_ssl:
    description:
      - Whether SSL encryption is required for connections
    required: true
  public_certificate:
    description:
      - Path to the SSL cert for the python driver to handshake with, usually in .pem format
    required: false
  private_certificate:
    description:
      - Path to the SSL certificates private key, usually in .key format
    required: false
  login_hosts:
    description:
      - List of hosts to login to Cassandra with
    required: true
  login_user:
    description:
      - The superuser to login to Cassandra with
    required: true
  login_password:
    description:
      - The superuser password to login to Cassandra with
    required: true
  login_port:
    description:
      - Port to connect to cassandra on
    default: 9042

notes:
   - "requires cassandra-driver to be installed"

'''

EXAMPLES = '''
# Create Role
- cassandra_security_replication: keyspace_name='SYSTEM_AUTH' replication_class='NetworkTopologyStrategy' replication_dc={'dse_core': 3, 'dse_search': 3}
'''

import ssl

try:
    from dse.cluster import Cluster
    from dse.auth import PlainTextAuthProvider
    from dse.query import dict_factory
except ImportError:
    cassandra_dep_found = False
else:
    cassandra_dep_found = True

def calculate_keyspace_replication(replication_dc):
    
    replication_dc_str = ''
    for dc_name, node_count in replication_dc.items():
        #if the number of nodes in a DC is zero do not output the DC
        if int(node_count) != 0:
            #DCs < 3x nodes use an RF=1
            if int(node_count) < 3:
                replication_dc_str = replication_dc_str + ", \'" + dc_name + "\': 1"
            #DCs < 9x nodes use an RF=3
            elif int(node_count) > 3 and int(node_count) < 9:
                replication_dc_str = replication_dc_str + ", \'" + dc_name + "\': 3"
            #DCs > 9x nodes use an RF=5
            elif int(node_count) > 9:
                replication_dc_str = replication_dc_str + ", \'" + dc_name + "\': 5"
                
    return replication_dc_str

def main():
    module = AnsibleModule(
        argument_spec={
            'keyspace_name': {
                'required': True,
                'type': 'str'
            },
            'replication_class': {
                'required': True,
                'type': 'str'
            },
            'replication_dc': {
                'required': True,
                'type': 'dict'
            },
            'is_ssl': {
                'required': True,
                'type': 'bool'
            },
            'public_certificate': {
                'required': False,
                'type': 'str'
            },
            'private_key': {
                'required': False,
                'type': 'str'
            },
            'login_user': {
                'required': True,
                'type': 'str'
            },
            'login_password': {
                'required': True,
                'no_log': True,
                'type': 'str'
            },
            'login_hosts': {
                'required': True,
                'type': 'list'
            },
            'login_port': {
                'default': 9042,
                'type': 'int'
            }
        },
        supports_check_mode=True
    )
    
    keyspace_name      = module.params["keyspace_name"]
    replication_class  = module.params["replication_class"]
    replication_dc     = module.params["replication_dc"]
    is_ssl             = module.params["is_ssl"]
    public_certificate = module.params["public_certificate"]
    private_key        = module.params["private_key"]
    login_user         = module.params["login_user"]
    login_password     = module.params["login_password"]
    login_hosts        = module.params["login_hosts"]
    login_port         = module.params["login_port"]

    if not cassandra_dep_found:
        module.fail_json(msg="the python cassandra-driver module is required")

    session = None
    changed = True
    ssl_options=dict(certfile=public_certificate, keyfile=private_key, ssl_version=ssl.PROTOCOL_TLSv1)
    
    try:
        if not login_user:
            cluster = Cluster(login_hosts, port=login_port)

        else:
            auth_provider = PlainTextAuthProvider(username=login_user, password=login_password)
            
            if is_ssl:
                cluster = Cluster(login_hosts, auth_provider=auth_provider, protocol_version=3.3, port=login_port, ssl_options=ssl_options)
            else:
                cluster = Cluster(login_hosts, auth_provider=auth_provider, protocol_version=3.3, port=login_port)
            
            session = cluster.connect()
            session.row_factory = dict_factory
    except Exception, e:
        module.fail_json(
            msg="unable to connect to cassandra, check login_user and login_password are correct. Exception message: %s" % e)
            
    try:
        replication_dc_str = calculate_keyspace_replication(replication_dc)
        query_str = "ALTER KEYSPACE " + keyspace_name + " WITH REPLICATION = {\'class\': \'" + replication_class + "\'" + replication_dc_str + "};"
        session.execute(query_str)
    except Exception, e:
        module.fail_json(msg=str(e))
    
    module.exit_json(changed=changed, keyspace_name=keyspace_name, query_str=query_str)

from ansible.module_utils.basic import *

if __name__ == '__main__':
    main()
