# Fill after running bootstrap (terraform output from bootstrap/)
resource_group_name  = "rg-tfstate-enterprise"
storage_account_name = "sttfstate61cax6"
container_name       = "tfstate-dev"
key                  = "enterprise.tfstate"
