
## Quickstart steps for initial cluster creation

#### Manual method for basic AWS environments (non VPC):

This process creates your initial DSE cluster AND a seperate OpsCenter cluster for metrics.

1. Set all params and cluster topology in `terraform_extended/variables.tf`
2. Set all port rules and security in `terraform_extended/ec2.tf`
3. Copy the directory `ansible/group_vars/all_example` to `ansible/group_vars/all` and set paths and vars marked with `[EDIT]` only
4. Change `ansible/group_vars/all/vars.yml` to a symbolic link pointing at `ansible/group_vars/all_example/vars.yml`, you now have default settings for all paramters.
5. Override any default settings in `ansible/group_vars/all_example/vars.yml` by placing the parameter in the `ansible/group_vars/all/my.yml` file with  [my_] in front it.

e.g. if a setting is [dse_repo_email] in `ansible/group_vars/all_example/vars.yml` override it with [my_dse_repo_email] in `ansible/group_vars/all/my.yml`


6. Run `./runterra_extended.sh` and check AWS instances that will be created - accept and run the plan
7. Run `./genansinv_extended.sh` (it will generate the required `/ansible/hosts` file)
8. Run `./runansi_extended.sh` (expects your key to be: `~/.ssh/id_rsa_aws`, edit if necessary)

MUST SEE BELOW for a more full description and more detailed instructions - you will need to set command line arguements to each of the scripts in 6) 7) and 8)

#### Dynamic inventory method for VPC environments:

You are expected to supply your own Terraform scripts, then take advantage of dynamic inventory in TerraDSE, plese read the documentation for dynamic inventory generation: [HERE](https://github.com/thompson42/terraform-dynamic-inventory) and then:

1. Copy the directory `ansible/group_vars/all_example` to `ansible/group_vars/all` and set paths and vars marked with `[EDIT]` only
2. Change `ansible/group_vars/all/vars.yml` to a symbolic link pointing at `ansible/group_vars/all_example/vars.yml`, you now have default settings for all paramters.
3. Override any default settings in `ansible/group_vars/all_example/vars.yml` by placing the parameter in the `ansible/group_vars/all/my.yml` file with  [my_] in front it.

e.g. if a setting is [dse_repo_email] in `ansible/group_vars/all_example/vars.yml` override it with [my_dse_repo_email] in `ansible/group_vars/all/my.yml`

4. Run `./runansi_extended.sh` (expects your key to be: `~/.ssh/id_rsa_aws`, edit if necessary)

```
NOTE: A NEW DYNAMIC INVENTORY PROCESS IS NOW AVAILABLE, SEE THE REPO AND INSTRUCTIONS ON HOW TO USE IT WITH TERRADSE [HERE](https://github.com/thompson42/terraform-dynamic-inventory)
```
