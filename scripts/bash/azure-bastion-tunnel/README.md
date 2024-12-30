# Azure Bastion Tunnler

This script is used if you have more than one Azure VM that you want to connect using Azure Bastion CLI. Can also be handy to do port forwarding when using `ssh`.

Be sure to login using `az login` and install the following extensions
```
az extension add -n bastion
az extension add -n ssh
```

Reference: https://learn.microsoft.com/en-us/cli/azure/network/bastion?view=azure-cli-latest