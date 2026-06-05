# Azure Scripts

- `bastion-tunnel.sh`: Creates SSH tunnels through Azure Bastion to one or more target VMs. Useful for connecting to multiple VMs or port forwarding via `ssh`.
    - Requires `az login` and the `bastion` + `ssh` extensions
- `get-deallocated-disks.sh`: Lists Azure managed disks that are in a deallocated state.
- `get-running-vms.sh`: Lists Azure virtual machines that are currently running.
