
## Generate Ansible Inventory File (ansible/hosts)

After the infrastructure instances have been provisioned, we need to install and configure DSE and OpsCenter and these instances accordingly, which is through the Ansible framework that I presented before at [here](https://github.com/yabinmeng/dseansible). One key item in the Ansible framework is the Ansible inventory file which determines key DSE node characteristics such as node IP, seed node, VNode, workload type, and so on. 

Now since we have provisioned the instances using terraform script, it is possible to generate the Ansible inventory file programmatically from terraform output state. Basically the idea is as below:
1. Generate terraform output state in a text file:

  ```sh
  terraform show terraform_extended/terraform.tfstate > $TFSTATE_FILE
  ```

2. Scan the terraform output state text file to generate a file that contains each instance's target DC tag, public IP, and private IP. An example is provided in this repository at: [dse_ec2IpList](https://github.com/thompson42/terradse/blob/master/dse_ec2IpList)

3. The same IP list information can also be used to generate the required Ansible inventory file. In the script, the first node in any DSE DC is automatically picked as the seed node. An example of the generated Ansible inventory file is provided in this repository: [dse_ansHosts](https://github.com/thompson/terradse/blob/master/dse_ansHosts)

A linux script file, ***genansinv_extended.sh***, is providied for this purpose. The script has 1 configurable parameter via input parameters. These parameters will impact the target DSE cluster topology information (as presented in the Ansible inventory file) a bit. Please adjust accordingly for your own case.

1. Script input argument: number of seed nodes per DC, default at 1

  ```sh
  ./genansinv_extended.sh [<number_of_seeds_per_dc>]
  ```
2. e.g.:

  ```
  ./genansinv_extended.sh 1
  ```

