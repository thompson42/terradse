#! /usr/bin/env python2

import json
import os
import os.path
import re
import subprocess
import sys

class TerraformDynamicInventory():
    
    def __init__(self, tfstate_path, tfstate_latest_path):
        
        self.tfstate_path        = tfstate_path
        self.tfstate_latest_path = tfstate_latest_path
        self.tfstate             = None
        self.tfstate_latest      = None  
        self.difference_type     = None
        self.original_inventory  = None
        self.latest_inventory    = None
        self.latest_dc_count     = None   
        self.original_dc_count   = None
        self.original_node_count = None
        self.latest_node_count   = None         
    
    def init_inventory(self):
        return {
            "all": {
                "hosts": [],
                "children": ["dse", "dse_core","dse_search","dse_analytics","dse_graph","opsc_dsecore","opsc_srv","add_node","add_datacenter"],
                "vars": {}
            },
            "dse": {
                "hosts": [],
                "children": ["dse_core","dse_search","dse_analytics","dse_graph"],
                "vars": {
                    "cluster_name": "DseCluster"
                }            
            },
            "dse_core": {
                "hosts": [],
                "children": [],
                "vars": {
                    "solr_enabled": 0,
                    "spark_enabled": 0,
                    "graph_enabled": 0,
                    "auto_bootstrap": 1
                }
            },
            "dse_search": {
                "hosts": [],
                "children": [],
                "vars": {
                    "solr_enabled": 1,
                    "spark_enabled": 0,
                    "graph_enabled": 0,
                    "auto_bootstrap": 1
                },
            },        
            "dse_analytics": {
                "hosts": [],
                "children": [],
                "vars": {
                    "solr_enabled": 0,
                    "spark_enabled": 1,
                    "graph_enabled": 0,
                    "auto_bootstrap": 1
                },
            },        
            "dse_graph": {
                "hosts": [],
                "children": [],
                "vars": {
                    "solr_enabled": 0,
                    "spark_enabled": 0,
                    "graph_enabled": 1,
                    "auto_bootstrap": 1
                },
            },
            "opsc_dsecore": {
                "hosts": [],
                "children": [],
                "vars": {
                    "cluster_name": "OpscCluster",
                    "solr_enabled": 0,
                    "spark_enabled": 0,
                    "graph_enabled": 0,
                    "auto_bootstrap": 1                
                },
            },        
            "opsc_srv": {
                "hosts": [],
                "vars": {},
                "children": []
            },
            "_meta": {
                "hostvars": {}
            },
            "add_node": self.init_group(), 
            "add_datacenter": self.init_group()       
        }

    def init_group(self, children=None, hosts=None):
        return {
            "hosts": [] if hosts is None else hosts,
            "children": [] if children is None else children,
            "vars": {
                    "solr_enabled": 0,
                    "spark_enabled": 0,
                    "graph_enabled": 0,
                    "auto_bootstrap": 0                
            }
        }

    def add_node_to_inventory(self, dse_datacenter_name, dse_node_type, node, inventory):   
        
        #always add the host to 'all' group (convention)
        inventory['all']['hosts'].append(node['private_ip'])
        
        is_seed_node = False
        
        if dse_datacenter_name not in inventory.keys():
            is_seed_node = True
            
            #always add the group to 'all' group (convention)
            inventory['all']['children'].append(dse_datacenter_name)
            
            #create a newly initialised group and add the node to the group 
            inventory[dse_datacenter_name] = self.init_group(hosts=[node['private_ip']])
            
            #set the datacenter's group vars node type
            dse_node_type = node['tags.DSENodeType']
            if dse_node_type == 'dse_graph':
                inventory[dse_datacenter_name]['vars']['graph_enabled'] = 1
            elif dse_node_type == 'dse_analytics':
                inventory[dse_datacenter_name]['vars']['spark_enabled'] = 1
            elif dse_node_type == 'dse_solr':
                inventory[dse_datacenter_name]['vars']['solr_enabled'] = 1
        
            #set the datacenter to auto bootstrap=false
            inventory[dse_datacenter_name]['vars']['auto_bootstrap'] = 1

            #add the dc name to dse:children if not OPSC
            if dse_datacenter_name not in inventory['dse']['children'] and dse_datacenter_name != 'opsc_dsecore':
                inventory['dse']['children'].append(dse_datacenter_name)
    
        elif node['private_ip'] not in inventory[dse_datacenter_name]:
            
            #if the dse_datacenter_name is opsc_dsecore
            if dse_datacenter_name == 'opsc_dsecore':
                if len(inventory['opsc_dsecore']['hosts']) == 0:
                    
                    #this is the first opsc_dsecore node, make it the opsc server
                    inventory['opsc_srv']['hosts'].append(node['private_ip'])
            
            #add the node to an existing group
            inventory[dse_datacenter_name]["hosts"].append(node['private_ip'])
            
            #if this is one of the first 3 nodes
            if len(inventory[dse_datacenter_name]["hosts"]) <= 3:
                is_seed_node = True
            
        #add the node to meta vars
        inventory["_meta"]["hostvars"][node['private_ip']] = node
        
        #add vars to _meta variables
        inventory["_meta"]["hostvars"][node['private_ip']]['dc'] = dse_datacenter_name
        inventory["_meta"]["hostvars"][node['private_ip']]['rack'] = 'RAC1'
        inventory["_meta"]["hostvars"][node['private_ip']]['vnode'] = '1'
        inventory["_meta"]["hostvars"][node['private_ip']]['initial_token'] = '0'
        
        if is_seed_node:
            inventory["_meta"]["hostvars"][node['private_ip']]['seed'] = 'true'
        else:
            inventory["_meta"]["hostvars"][node['private_ip']]['seed'] = 'false'
        
        #clear out any verbose or sensitive fields
        inventory["_meta"]["hostvars"][node['private_ip']]['user_data_base64'] = "cleared"
        
        return inventory

    #build and return the inventory
    def build_inventory(self, tfstate_object, inventory):
        for module in tfstate_object["modules"]:
            for resource in module["resources"].values():
                if resource["type"].startswith("aws_instance"):
                    node = resource["primary"]["attributes"]
                    inventory = self.add_node_to_inventory(node['tags.DSEDataCenterName'], node['tags.DSENodeType'], node, inventory)
        
        return inventory

    #get the count of aws_instances in the original tfstate file
    def getAwsInstanceCount(self, tfstate_json_object):
    
        count = 0
        
        try:
            
            for module in tfstate_json_object["modules"]:
                for resource in module["resources"].values():
                    if resource["type"].startswith("aws_instance"):
                        count = count + 1
        except:
            pass
    
        return count
    
    #used by add_node, return the ip-address of the added node
    def getAddNodeIp(self):
        
        #loop over latest tfstate ip addresses testing against original
        for ip in self.latest_inventory['all']['hosts']:
            if ip not in self.original_inventory['all']['hosts']:
                return ip
    
    #used by add_datacenter, return the list of ip addresses for the new nodes in the new datacenter
    def getNewNodeIpList(self):
        
        new_node_ip_list = []
        
        #loop over latest tfstate ip addresses testing against original
        for ip in self.latest_inventory['all']['hosts']:
            if ip not in self.original_inventory['all']['hosts']:
                new_node_ip_list.append(ip)
        
        return new_node_ip_list
    
    def getAddDataCenterName(self):
            
        #loop over latest tfstate dc names testing against original
        for dc_name in self.latest_inventory['all']['children']:
            if dc_name not in self.original_inventory['all']['children']:
                return dc_name

    def build_modified_inventory(self):
        
        #take the original inventory and modify it
        
        #difference the 2x TFSTATES - difference can be None, add_node or add_datacenter
        self.get_difference_type()
        
        if self.difference_type is None:
            sys.stdout.write("There is no difference in your TFSTATE files, therefore no work top do, exiting now.")
            sys.exit(1)
            
        if self.difference_type == 'add_node':
            #check the user is only trying to add one node
            if self.latest_node_count - self.original_node_count != 1:
                sys.stdout.write("You appear to be trying to add more than a single node at a time, this is NOT supported.")
                sys.exit(1)
                
            #identify the node they are adding
            add_node_ip = self.getAddNodeIp()
            
            #populate 'all' with the new node ip
            self.original_inventory['all']['hosts'].append(add_node_ip)
            
            #populate the [add_node] group with the new node
            self.original_inventory['add_node']['hosts'].append(add_node_ip)
            
            #populate the _meta vars with the new node's vars
            self.original_inventory["_meta"]["hostvars"][add_node_ip] = self.latest_inventory["_meta"]["hostvars"][add_node_ip]
                    
            #make sure added node is not a seed
            self.original_inventory["_meta"]["hostvars"][add_node_ip]['seed'] = 'false'
            
            #set the datacenter's group vars node type
            dse_node_type = self.latest_inventory["_meta"]["hostvars"][add_node_ip]['tags.DSENodeType']
            if dse_node_type == 'dse_graph':
                self.original_inventory['add_node']["vars"]['graph_enabled'] = 1
            elif dse_node_type == 'dse_analytics':
                self.original_inventory['add_node']["vars"]['spark_enabled'] = 1
            elif dse_node_type == 'dse_solr':
                self.original_inventory['add_node']['vars']['solr_enabled'] = 1            
            
            #need to auto_bootstrap this node
            self.original_inventory['add_node']['vars']['auto_bootstrap'] = 1
                
        if self.difference_type == 'add_datacenter':
            #check the user is only trying to add one node
            if self.latest_dc_count - self.original_dc_count != 1:
                sys.stdout.write("You appear to be trying to add more than a single datacenter at a time, this is NOT supported.")
                sys.exit(1)
                
            #identify the datacenter they are adding
            add_datacenter_name = self.getAddDataCenterName()
            
            #populate ['all']['children'] with add_datacenter group - DONE
            #populate ['all']['hosts'] with the new node ip-addresses
            #populate [add_datacenter]['hosts'] with the new node ip-addresses
            new_node_ip_list = self.getNewNodeIpList()
            for ip in new_node_ip_list:
                self.original_inventory['all']['hosts'].append(ip)
                self.original_inventory['add_datacenter']['hosts'].append(ip)
            
            #populate original_inventory["_meta"]["hostvars"] with the new nodes' vars
            for ip in new_node_ip_list:
                self.original_inventory["_meta"]["hostvars"][ip] = self.latest_inventory["_meta"]["hostvars"][ip]

            #set the datacenter's type off one of the new nodes
            dse_node_type = self.latest_inventory["_meta"]["hostvars"][ip]['tags.DSENodeType']
            if dse_node_type == 'dse_graph':
                self.original_inventory['add_datacenter']['vars']['graph_enabled'] = 1
            elif dse_node_type == 'dse_analytics':
                self.original_inventory['add_datacenter']['vars']['spark_enabled'] = 1
            elif dse_node_type == 'dse_solr':
                self.original_inventory['add_datacenter']['vars']['solr_enabled'] = 1
        
            #set the datacenter to auto bootstrap=false
            self.original_inventory['add_datacenter']['vars']['auto_bootstrap'] = 0
    
    def cluster_initialisation_required(self):
        
        #to get here we have a valid original tfstate but an unknown tfstate_latest
        
        # tfstate_latest_path = None
        # output the original tfstate only
        if self.tfstate_latest_path == None:
            return True
        
        # No valid file at tfstate_latest_path
        # output the original tfstate only
        if not os.path.isfile(self.tfstate_latest_path):
            return True
        
        # No valid JSON file at tfstate_latest_path
        # bubble up exception
        with open(self.tfstate_latest_path) as f:
            self.tfstate_latest = json.load(f)
        
        # No aws_instances in tfstate_latest
        # output the original tfstate only
        aws_instance_count = self.getAwsInstanceCount(self.tfstate_latest)
        if aws_instance_count == 0:        
            sys.stdout.write("A TFSTATE LATEST file was found but contains no aws_instances, please check your tfstate_latest file: " + self.tfstate_latest_path)
            sys.exit(1)
        
        #we have a valid tfstate_latest file with aws_instances listed
        return False
        
        
    def get_difference_type(self):
        
        #difference can be None, add_node or add_datacenter  
        self.original_inventory = self.build_inventory(self.tfstate, self.init_inventory())
        self.original_dc_count = len(self.original_inventory['all']['children'])  
            
        self.latest_inventory = self.build_inventory(self.tfstate_latest, self.init_inventory())
        self.latest_dc_count = len(self.latest_inventory['all']['children'])
        
        if self.original_dc_count != self.latest_dc_count:
            return 'add_datacenter'
        
        self.original_node_count = len(self.original_inventory['all']['hosts'])
        self.latest_node_count = len(self.latest_inventory['all']['hosts'])
        
        if self.original_node_count != self.latest_node_count:
            return 'add_node'    
        
        return None
    

    def main(self):
        try:
            
            
            if self.tfstate_path == None:
                sys.stdout.write("No TFSTATE file passed in")
                sys.exit(1)                
            
            if not os.path.isfile(self.tfstate_path):
                sys.stdout.write("No valid file object at TFSTATE PATH: " + self.tfstate_path)
                sys.exit(1)                
            
            #load into json, if it fails to load bubble up exception
            with open(self.tfstate_path) as f:
                self.tfstate = json.load(f)
            
            # if tfstate has zero(0) EC2 node instances in it -> exit
            aws_instance_count = self.getAwsInstanceCount(self.tfstate)
            if aws_instance_count == 0:
                sys.stdout.write("Original TFSTATE file exists but has zero aws_instances listed in it, please check the file at path: " + self.tfstate_path)
                sys.exit(1)             
            
            #find out if there are two TFSTATE files to compare, otherwise this is an initial run
            is_cluster_initialisation_required = self.cluster_initialisation_required()
            
            if is_cluster_initialisation_required:
                    inventory = self.build_inventory(self.tfstate, self.init_inventory())
            else:
                #difference the 2x TFSTATES - difference can be None, add_node or add_datacenter
                self.difference_type = self.get_difference_type()
                
                if self.difference_type is None:
                    sys.stdout.write("No difference exixts between the old and new TFSTATE files, no work to do.")
                    sys.exit(1)
                
                self.build_modified_inventory()
                inventory = self.original_inventory
                
            sys.stdout.write(json.dumps(inventory, indent=2))
            
        except Exception as ex:
            sys.stdout.write("An exception occured generating the dynamic inventory, plese check your TFSTATE file/s: " + str(ex))
            sys.exit(1)
            
        return json.dumps(inventory, indent=2)

if __name__ == '__main__':
    
    """
    TESTING - tfstate
    -----------------
    
    tfstate_path        = None
    tfstate_latest_path = None
    
    tfstate_path        = "inventory_generator_test_data/no_file"
    tfstate_latest_path = None
    
    tfstate_path        = "inventory_generator_test_data/tfstate_empty_file.json"
    tfstate_latest_path = None
    
    tfstate_path        = "inventory_generator_test_data/tfstate_invalid_json.json"
    tfstate_latest_path = None
    
    tfstate_path        = "inventory_generator_test_data/tfstate_no_aws_instances_json.json"
    tfstate_latest_path = None
    
    #Success case:
    tfstate_path        = "inventory_generator_test_data/tfstate_valid.json"
    tfstate_latest_path = None
    
    TESTING - tfstate_latest
    ------------------------
    
    tfstate_path        = "inventory_generator_test_data/tfstate_valid.json"
    tfstate_latest_path = "inventory_generator_test_data/no_file"
    
    tfstate_path        = "inventory_generator_test_data/tfstate_valid.json"
    tfstate_latest_path = "inventory_generator_test_data/tfstate_empty_file.json"
    
    tfstate_path        = "inventory_generator_test_data/tfstate_valid.json"
    tfstate_latest_path = "inventory_generator_test_data/tfstate_invalid_json.json"
    
    tfstate_path        = "inventory_generator_test_data/tfstate_valid.json"
    tfstate_latest_path = "inventory_generator_test_data/tfstate_no_aws_instances_json.json"
    
    # No change
    tfstate_path        = "inventory_generator_test_data/tfstate_valid.json"
    tfstate_latest_path = "inventory_generator_test_data/tfstate_valid.json"
    
    #Success cases:
    tfstate_path        = "inventory_generator_test_data/tfstate_valid.json"
    tfstate_latest_path = "inventory_generator_test_data/tfstate_latest_add_node.json"
    
    tfstate_path        = "inventory_generator_test_data/tfstate_valid.json"
    tfstate_latest_path = "inventory_generator_test_data/tfstate_latest_add_datacenter.json"
    
    
    """
    
    tfstate_path        = os.getenv('DYNAMIC_INVENTORY_TFSTATE_PATH')
    tfstate_latest_path = os.getenv('DYNAMIC_INVENTORY_TFSTATE_LATEST_PATH')
    tdi                 = TerraformDynamicInventory(tfstate_path, tfstate_latest_path)
    tdi.main()