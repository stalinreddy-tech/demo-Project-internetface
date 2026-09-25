# Fill after running bootstrap (same storage account as other envs; different container)
resource_group_name  = "rg-tfstate-internetface"
storage_account_name = "REPLACE_WITH_BOOTSTRAP_STORAGE_ACCOUNT"
container_name       = "tfstate-qa"
key                  = "internetface.tfstate"
