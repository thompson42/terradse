#!/usr/bin/python
# -*- coding: utf-8 -*-


DOCUMENTATION = '''
---
module: keyspace_replication_configure

short_description: Manage Cassandra Keyspace Replication and Topology Strategies
description:
    - Manage Cassandra Keyspace Replication and Topology Strategies
    - requires `pip install cassandra-driver`
    - Related Docs: https://datastax.github.io/python-driver/api/cassandra/query.html
    - Related Docs: https://docs.datastax.com/en/cql/3.3/cql/cql_reference/create_role.html
author: "Alex Thompson"
options:
  keyspace_name:
    description:
      - name of the keyspace to ALTER, e.g. DSE_SECURITY or SYSTEM_AUTH
    required: true
  topology_strategy:
    description:
      - topology_strategy; usually NetworkTopologyStrategy
    required: true
  replication_dc:
    description:
      - a dictionary of dc_name:node_count pairs to construct the replication_factor from
    required: true
  is_ssl:
    description:
      - Whether SSL encryption is required for connections
    required: true
  cert_file:
    description:
      - Path to the public SSL certificate for the python driver
    required: false
  key_file:
    description:
      - Path to the private SSL key for the python driver
    required: false
  login_required:
    description:
      - Boolean whether login is required
    required: true
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
- cassandra_table_replication: keyspace_name='SYSTEM_AUTH' topology_strategy='NetworkTopologyStrategy' replication_dc={'dse_core': 3, 'dse_search': 3}
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

def calculate_keyspace_replication(replication_dc, keyspace_name):
    
    replication_dc_str = ''
    for dc_name, node_count in replication_dc.items():
        #if the number of nodes in a DC is zero do not output the DC
        if int(node_count) != 0:
            #DCs < 3x nodes use an RF=1
            if int(node_count) < 3:
                replication_dc_str = replication_dc_str + ", \'" + dc_name + "\': 1"
            #DCs >= 3x nodes use an RF=3
            elif int(node_count) >= 3:
                replication_dc_str = replication_dc_str + ", \'" + dc_name + "\': 3"
            #DCs > 9x nodes use an RF=5
            elif int(node_count) > 9:
                if keyspace_name.lower() == 'system_auth' or keyspace_name.lower() == 'dse_security':
                    replication_dc_str = replication_dc_str + ", \'" + dc_name + "\': 5"
                else:
                    replication_dc_str = replication_dc_str + ", \'" + dc_name + "\': 3"
                
    return replication_dc_str

def main():
    module = AnsibleModule(
        argument_spec={
            'keyspace_name': {
                'required': True,
                'type': 'str'
            },
            'topology_strategy': {
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
            'cert_file': {
                'required': False,
                'type': 'str'
            },
            'key_file': {
                'required': False,
                'type': 'str'
            }, 
            'login_required': {
                'required': True,
                'type': 'bool'
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
    
    keyspace_name     = module.params["keyspace_name"]
    topology_strategy = module.params["topology_strategy"]
    replication_dc    = module.params["replication_dc"]
    is_ssl            = module.params["is_ssl"]
    cert_file         = module.params["cert_file"]
    key_file          = module.params["key_file"]
    login_required    = module.params["login_required"]
    login_user        = module.params["login_user"]
    login_password    = module.params["login_password"]
    login_hosts       = module.params["login_hosts"]
    login_port        = module.params["login_port"]

    #exit if no cassandra driver found
    if not cassandra_dep_found:
        module.fail_json(msg="the python cassandra-driver module is required")

    session = None
    changed = True
    ssl_options = dict(certfile=cert_file, keyfile=key_file, ssl_version=ssl.PROTOCOL_TLSv1)
    
    #connect to the cluster                               
    try:
        if not login_required:
            cluster = Cluster(login_hosts, port=login_port)

        else:
            auth_provider = PlainTextAuthProvider(username=login_user, password=login_password)
            
            if is_ssl:
                cluster = Cluster(login_hosts, auth_provider=auth_provider, protocol_version=3.3, port=login_port, ssl_options=ssl_options)
            else:
                cluster = Cluster(login_hosts, auth_provider=auth_provider, protocol_version=3.3, port=login_port)
            
        session = cluster.connect()
        
    except Exception, e:
        module.fail_json(
            msg="unable to connect to cassandra, check login_user and login_password are correct. Exception message: %s" % e)
    
    #issue the query        
    try:
        #build the replication string
        replication_dc_str = calculate_keyspace_replication(replication_dc, keyspace_name)
        
        #build the final query
        if keyspace_name == "HiveMetaStore":
            query_str = "ALTER KEYSPACE \"" + keyspace_name + "\" WITH REPLICATION = {\'class\': \'" + topology_strategy + "\'" + replication_dc_str + "};"
        else:
            query_str = "ALTER KEYSPACE " + keyspace_name + " WITH REPLICATION = {\'class\': \'" + topology_strategy + "\'" + replication_dc_str + "};"
        
        #execute the CQL command
        session.execute(query_str)
        
    except Exception, e:
        module.fail_json(msg=str(e))
    
    module.exit_json(changed=changed, keyspace_name=keyspace_name, query_str=query_str)

from ansible.module_utils.basic import *

if __name__ == '__main__':
    main()
