
# Generate dynamic Ansible inventory off Terraform .tfstate files for TerraDSE

This small module in the ansible/library/dynamic_inventory.py file will generate a dynamic inventory in JSON format for Ansible via tfstate files.

#### Configuration

##### ancible.cfg setting

To activate the dynamic inventory change the inventory key to the following:

```
inventory = library/inventory_generator.py
```

##### AWS Tags

The inventory is controlled by two AWS tags on each instance e.g.:

```
"tags.DSEDataCenterName": "dse_graph",
"tags.DSENodeType": "dse_graph",

```

Make sure you tag all nodes (instances) with both tags.

##### Environment variables

Set following environment variables (consumed by the inventory_generator.py file) e.g.:

```
DYNAMIC_INVENTORY_TFSTATE_PATH="/path/to/tfstate"
DYNAMIC_INVENTORY_TFSTATE_LATEST_PATH="/path/to/tfstate_latest"
```

These will need to be added to your /etc/environment file as key=value:

```
DYNAMIC_INVENTORY_TFSTATE_PATH="/path/to/tfstate"
DYNAMIC_INVENTORY_TFSTATE_LATEST_PATH="/path/to/tfstate_latest"
```

Then reload the environment file temporarily via the following command, this will only work for the existing shell:

```
source /etc/environment
```

Reboot the OS on the ansible node to persist these environment variables and make them available for all users.

To check you correctly set the paths:

```
echo $DYNAMIC_INVENTORY_TFSTATE_PATH
echo $DYNAMIC_INVENTORY_TFSTATE_LATEST_PATH
```

#### Usage

With the AWS tags and environment variables correctly set on existing Terraform tfstate and a new Terraform tfstate we have enough information to generate a dynamic inventory for ansible, avoiding the need to maintain [hosts] files for ansible, we also have the added advantage of being able to version tfstate files in S3 etc.

Case 1: If only a single Terraform tfstate file exists at the first variable path; DYNAMIC_INVENTORY_TFSTATE_PATH and the second path; DYNAMIC_INVENTORY_TFSTATE_LATEST_PATH  is empty,  the dynamic inventory script will build the Ansible inventory describing the current state, this can be used to generate a new cluster, or used to perform work on the existing cluster.

Case 2: If two Terraform tfstate files exist the dynamic inventory script will difference the two states and work out your intentions:

Case 2 A: If no difference there is no work to do, an empty inventory will be supplied to Ansible and it should exit with no work done.

Case 2 B: If differences found the script will work out your intentions which will be either [add_node] or [add_datacenter]

If you attempt to add more than 1x node to an existing datacenter the script will exit and fail.

If you attempt to add more than 1x datacenter to an existing cluster the script will exit and fail.

### To debug inventory_generator.py

To dbug the script or just to see how it works prior to using it in ansible call the script outside of ansible on the command line directly:

```
>python inventory_generator.py
```
You will need to make sure the ENVIRONMENT variables: DYNAMIC_INVENTORY_TFSTATE_PATH (and optionally DYNAMIC_INVENTORY_TFSTATE_LATEST_PATH)  in the script are correct.

Output will be an inventory in Ansible compliant format.

### Initial cluster build example, single Terraform tfstate:

```
instance 1{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 2{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 3{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 4{
    ....
    "tags.DSEDataCenterName": "opsc_dsecore",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 5{
    ....
    "tags.DSEDataCenterName": "opsc_dsecore",
    "tags.DSENodeType": "dse_core",
    ....
}

```

From this single Terraform tfstate the dynamic inventory is the initial spin up of a TerraDSE cluster due to the fact there is no prior state file (i.e. not 2x tfstate files supplied to the script)

### Add a node example [add_node], two Terraform tfstate files:

Original tfstate:

```
instance 1{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 2{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 3{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 4{
    ....
    "tags.DSEDataCenterName": "opsc_dsecore",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 5{
    ....
    "tags.DSEDataCenterName": "opsc_dsecore",
    "tags.DSENodeType": "dse_core",
    ....
}

```

New tfstate:

```
instance 1{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 2{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 3{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 4{
    ....
    "tags.DSEDataCenterName": "opsc_dsecore",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 5{
    ....
    "tags.DSEDataCenterName": "opsc_dsecore",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 6{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}

```

Note that "instance 6" is the difference between the two Terraform tfstate files, it is an additional node going into an existing datacenter called dse_core

### Add a datacenter example [add_datacenter], two Terraform tfstate files:

Original tfstate:

```
instance 1{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 2{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 3{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 4{
    ....
    "tags.DSEDataCenterName": "opsc_dsecore",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 5{
    ....
    "tags.DSEDataCenterName": "opsc_dsecore",
    "tags.DSENodeType": "dse_core",
    ....
}

```

New tfstate:

```
instance 1{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 2{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 3{
    ....
    "tags.DSEDataCenterName": "dse_core",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 4{
    ....
    "tags.DSEDataCenterName": "opsc_dsecore",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 5{
    ....
    "tags.DSEDataCenterName": "opsc_dsecore",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 6{
    ....
    "tags.DSEDataCenterName": "dse_core_2",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 7{
    ....
    "tags.DSEDataCenterName": "dse_core_2",
    "tags.DSENodeType": "dse_core",
    ....
}
instance 8{
    ....
    "tags.DSEDataCenterName": "dse_core_2",
    "tags.DSENodeType": "dse_core",
    ....
}

```

Note that the difference is instances 6,7,8 and that they are configured to go into a new datacenter called: dse_core_2 of type dse_core (Cassandra only)
