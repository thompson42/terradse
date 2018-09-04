

## Quickstart steps to add a new node to an existing datacenter

TESTING

Note: You will need the `ansible/hosts` file from the above cluster creation process to successfully add a node to this cluster due to the fact we have to regenerate keystores in some cases to add the new node's certificate. The hosts file needs to be 100% accurate, do NOT attempt to add a node into this cluster if you are not sure the hosts file is accurate.

1. Make sure you have a hosts file that reflects your target cluster AND a group_vars/all/my.vars that matches the existing nodes in the DC
2. Create your new node
3. Manually insert the new node's details into your hosts file, use the hosts_add_node_example file as a guide
4. In the hosts file create the [add_node] section and list the node below it
5. For the node listed under [add_node] in the dc= field put the name of the DC you are adding the node to
6. In the hosts file create the [add_node:vars] section with the same contents as in the hosts_add_node_example file
7. In the [add_node:vars] section configure your new node's type; spark, solr etc
8. Override default settings in group_vars/all/vars.yml with a my_ prefix in the group_vars/all/my.yml see group_vars/all_example for examples of how to do this.
9. Make sure all settings in group_vars/all/my.yml are the same as when the original cluster that was generated with this tool.
10. cd to the terraDSE directory and run ./runterra_add_node.sh and monitor Opscenter as the new node comes up.

If using a terraform dynamic inventory run your custom Terraform script with the required tags, ignore steps 1->8 and complete steps 9) and 10) - see instructions [HERE](https://github.com/thompson42/terraform-dynamic-inventory)

```
NOTE: A NEW DYNAMIC INVENTORY PROCESS IS NOW AVAILABLE, SEE THE REPO AND INSTRUCTIONS ON HOW TO USE IT WITH TERRADSE [HERE](https://github.com/thompson42/terraform-dynamic-inventory)
```
