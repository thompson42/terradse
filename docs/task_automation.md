
## Task automation

#### Rolling restart

A rolling restart of a DSE cluster is an important task that must be performed after some significant change has been made to a cluster and is documented in various processes.

A rolling restart is not a full cluster down, then cluster back up process but rather the downing of a single node and restart of the DSE process, this allows us to leave a cluster operational while performing changes to a cluster one node at a time; this is a very important uptime process unique to DSE/Cassandra.

TerraDSE contains a playbook that automates this process, you can invoke it on an ad-hoc basis by the following command:

```
ansible-playbook dse_cluster_rolling_restart.yml --private-key=~/.ssh/id_rsa_aws

```

Please note that if you are using: 

1. A manual inventory (explicit "hosts" file) that you will need to acertain it's a true representation of your cluster before running this command.
2. If using a dynamic inventory please acertain the accuracy of your TFSTATE file/s are a true representation of your cluster.






