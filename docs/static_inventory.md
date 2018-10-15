
# To use a static inventory (The DEFAULT setting)

Configure the ansible/hosts file manually paying special attention to accuracy, this file will need to exactly mirror your environment.

#### Configuration

##### ancible.cfg setting

To activate the static inventory change the inventory key to the following:

```
inventory = hosts
```
