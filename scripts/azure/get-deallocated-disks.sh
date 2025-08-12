#!/bin/bash

# Get resource IDs of deallocated VMs
for vm_id in $(az vm list -d --query "[?powerState=='VM deallocated'].id" -o tsv); do
  # Get disk ID for each VM
  osDisk_id=$(az vm show --ids $vm_id --query "{osDisk:storageProfile.osDisk.managedDisk.id}" -o tsv)
  # Print disk details
  az disk show --ids $osDisk_id --query "{name:name, size:diskSizeGB, sku:sku, location:location}"
  echo -e "\n"
done
