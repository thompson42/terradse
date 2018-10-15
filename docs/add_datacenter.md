
## Quickstart steps to add a full datacenter to an existing cluster

#### Manual method for basic AWS environments:

1. In ansible/ansible.cfg set inventory=hosts and set the full path for the private_key_file
2. Make sure you have a hosts file that reflects your target cluster AND a group_vars/all/my.vars that matches the existing nodes in the cluster
3. Create your new nodes
4. Manually insert the new nodes' details into your hosts file, use the hosts_add_datacenter_example file as a guide
5. In the hosts file create the [add_datacenter] section and list the nodes below it
6. For the nodes listed under [add_datacenter] in the dc= field put the name of your new DC: cannot be dse_graph, dse_search, dse_core or dse_analytics (they are reserved)
7. In the hosts file create the [add_datacenter:vars] section with the same contents as in the hosts_add_datacenter_example file
8. In the [add_datacenter:vars] section configure your new DCs type,\; spark, solr etc
9. Override default settings in group_vars/all/vars.yml with a my_ prefix in the group_vars/all/my.yml see group_vars/all_example for examples of how to do this.
10. Make sure all settings in group_vars/all/my.yml are the same as when the original cluster that was generated with this tool.
11. cd to the terraDSE directory and run ./runterra_add_datacenter.sh and monitor Opscenter as the new DC comes up.

#### Dynamic inventory method for VPC environments:

For dynamic inventory see instructions [HERE](dynamic_inventory.md)

If using the dynamic inventory run your custom Terraform script with the required tags:

1. In ansible/ansible.cfg set inventory=library/dynamic_inventory.py and set the full path for the private_key_file
2. Make sure all settings in group_vars/all/my.yml are the same as when the original cluster that was generated with this tool.
3. cd to the terraDSE directory and run ./runterra_add_datacenter.sh and monitor Opscenter as the new datacenter comes up.
