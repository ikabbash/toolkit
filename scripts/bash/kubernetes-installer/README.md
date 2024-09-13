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