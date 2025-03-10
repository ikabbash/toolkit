# Kubernetes Installer
- `init-k8s.sh` uses the latest version of [Kubespray](https://github.com/kubernetes-sigs/kubespray) to install a Kubernetes cluster for the targeted nodes in the `CLUSTER_NODES_IPS` array variable
- If the script will be used on more than one node, make sure that all nodes have the same username and a `sudo` privilege
- Passwordless login will be enabled on the target servers
- If the servers use a different SSH port you can change the target port in the `SSH_PORT` variable
- The script also installs latest versin of [Helm](https://github.com/helm/helm) and [Nginx Ingress Controller](https://github.com/nginxinc/kubernetes-ingress) tuned for production use
- To test, use `nginx-test.yaml` manifest which creates an Nginx deployment, service, and a virtual server

## Enhancements
- [ ] Add an option to create a secret for the container image registries using `kubectl create secret generic -n ${namespace} ${secret-name} --from-file=.dockerconfigjson=/path/to/config.json --type=kubernetes.io/dockerconfigjson`
- [ ] Add an option to create a TLS secret using `kubectl create secret -n ${namespace} tls ${secret_name} --cert=/path/to/crt --key=/path/to/key`
- [ ] Add code to deploy worker nodes instead of having all nodes to be controlplane (update step 3)
- [ ] Etcd is deployed as a static pod instead of the default systemd

## Local DNS Issue
- If you found your local DNS pod crashing with the following error after reboot, there's most likely an issue with the resolver configuration
    ```
    [FATAL] plugin/loop: Loop (169.254.25.10:42096 -> 169.254.25.10:53) detected for zone ".", see https://coredns.io/plugins/loop#troubleshooting. Query: "HINFO 8227980046591666151.5519681328841792818."
    ```
- You can refer to this (Github issue)[https://github.com/kubernetes-sigs/kubespray/issues/9948#issuecomment-1533876540] for more explanation and a workaround
- TLDR: Both coredns and nodelocaldns 'fall back' to the host's DNS setting, hence its stuck in a loop where its trying to resolve nodelocaldns then host and so on
- A way to fix it without having to use `resolvconf_mode: none` option that worked for me in my own VMWare setup is to make sure the content that's in `/run/systemd/resolve/resolv.conf` is in `/etc/resolv.conf` because that's what broke the loop
    - [Reference one](https://coredns.io/plugins/loop/#troubleshooting-loops-in-kubernetes-clusters)
    - [Reference two](https://stackoverflow.com/questions/54466359/coredns-crashloopbackoff-in-kubernetes)
    - If you're using VMWare with an automatic bridged network, you'll need a static IP address. Refer to this [documentation](https://ubuntu.com/server/docs/configuring-networks#static-ip-address-assignment)

## References
- https://github.com/kubernetes-sigs/kubespray/blob/master/docs/getting_started/getting-started.md
- https://github.com/kubernetes-sigs/kubespray/blob/master/inventory/sample/inventory.ini