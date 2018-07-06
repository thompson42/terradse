
# Bringing up a new named DC after original creation where both Node->Node encryption and SSL-Client-Auth are active in the original DC and no outage is acceptable

```
Implementing node -> node encryption - can be done with no downtime and no cluster splitting:

1. Create all certs, .truststores and .keystores and deploy them onto nodes in the old DC
2. On all nodes in the old DC set: internode_encryption: dc
3. Perform a rolling restart of all nodes in the old DC
3. Prepare all the nodes on the new DC with their certs, .truststores and .keystores and set: internode_encryption: all
4. Bring up the new DC

Summary: The old DC will talk to the new DC encrypted. 
And the new DC would talk everywhere encrypted.
```

1. seeds list points to one of the orig DCs
2. cassandra.yaml: autobootstrap=false
3. nodetool rebuild
4. ip-address of opsc_server for new agents
5. need to generate new keystores and truststores for ALL nodes ?

# Troubleshooting

#### DSE service does not start up in time. get an OS LSB service exception:

[WAIT_FOR_START](https://docs.datastax.com/en/dse-trblshoot/doc/troubleshooting/dseTimesOut.html)


