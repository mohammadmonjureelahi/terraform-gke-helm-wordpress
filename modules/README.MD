# This is a module folder where you would store all your tf modules and referece the relative path to the module foler you want to use

## IE: In my example I have terraform-gcp-cluster to bring up the initial kubernetes cluster and another folder terraform-gcp-cluster-env to add to the existing cluster.
## So if your working on the vault module, vault itself would go into the modules folder and you would reference that module in terraform-gcp-cluster-env.
## Leave terraform-gcp-cluster for ONLY creating kubernetes cluster (that way when you destroy during testing the cluster is still there its just the environment in the cluster you are destroying.)