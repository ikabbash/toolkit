#!/bin/bash

# Get all running VMs
for vm_id in $(az vm list -d --query "[?powerState=='VM running'].id" -o tsv); do
  az vm show --ids $vm_id \
    --query "{info: {name: name, region: location, size: hardwareProfile.vmSize, os: storageProfile.imageReference.offer, osDiskSize: storageProfile.osDisk.diskSizeGb, osDiskType: storageProfile.osDisk.managedDisk.storageAccountType}, dataDisks: storageProfile.dataDisks[].{name: name, sizeGb: diskSizeGb, type: managedDisk.storageAccountType}}" -o json
  echo -e "\n=========================\n"
done
