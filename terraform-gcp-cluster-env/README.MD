# In this repo you will specify kubernetes modules to deploy to your working cluster IE: This is where the vault and other kubernetes services would go, Remember EVERYTHING is a module so in the repo you should be creating a module in modules folder and referencing that module in main.tf here in this repo.

## You will need to manually create the namespace
### kubectl create namespace vault
## You will also need to manually create the kms key and fill in the correct values in the vault module
## There is also currently a bug in this release that you have to manually taint the resource in state to recreate the changes
### terraform taint module.vault.helm_release.vault