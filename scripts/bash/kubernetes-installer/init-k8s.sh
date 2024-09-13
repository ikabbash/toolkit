#!/bin/bash

set -e

cat << 'EOF'
+---------------------------------------------------------+
| _  _____           ___           _        _ _           |
|| |/ ( _ ) ___     |_ _|_ __  ___| |_ __ _| | | ___ _ __ |
|| ' // _ \/ __|     | || '_ \/ __| __/ _` | | |/ _ \ '__||
|| . \ (_) \__ \     | || | | \__ \ || (_| | | |  __/ |   |
||_|\_\___/|___/    |___|_| |_|___/\__\__,_|_|_|\___|_|   |
+---------------------------------------------------------+
EOF

# Define colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# Get the latest tag of any Github repo
get_latest_release () {
  local repo_path=$1
  git ls-remote --tags https://github.com/"${repo_path}".git | awk -F'/' '{print $NF}' | grep -v '{}' | grep -E '^[vV]?[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1
}

# For Kubespray setup
install_kubernetes() {
  echo -e "[defaults]\nroles_path = /usr/local/src/kubespray/roles" > ~/.ansible.cfg
  # Enable automatic renewal for cluster certs
  sed -i "s/auto_renew_certificates\: false/auto_renew_certificates: true/g" "${KUBESPRAY_SRC_DIR}"/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
  # Deploy kubernetes cluster using Ansible Playbook
  ansible-playbook -i "${KUBESPRAY_SRC_DIR}"/inventory/mycluster/hosts.yml -u ${USER} --become --become-user=root "${KUBESPRAY_SRC_DIR}"/cluster.yml
  echo -e "${BLUE}${BOLD}Cluster has been installed successfully${RESET}" && sleep 5
  # Test Kubernetes cluster installation
  echo -e "${BLUE}Validating the installed kubernetes cluster..${RESET}"
  sudo su -c "kubectl version"
  sudo su -c "kubectl get nodes -o wide"
  sudo su -c "kubectl get all -A"
  for CLUSTER_NODE_IP in "${CLUSTER_NODES_IPS[@]}"
  do
    ssh -t "${CLUSTER_NODE_IP}" "sudo su -c 'curl -k https://"${CLUSTER_NODE_IP}":6443/readyz?verbose'"
  done
}

# For Nginx ingress controller installation
install_helm() {
  cd /tmp
  curl -LO https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
  tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz
  sudo mv linux-amd64/helm /usr/local/bin/helm
  cd
}

BASE_DIR=$(readlink -f $(dirname ${0}))
SSH_PORT="22"
KUBESPRAY_SRC_DIR="/usr/local/src/kubespray"
PYTHON_ENV_DIR="${KUBESPRAY_SRC_DIR}/python-venv"
CLUSTER_NODES_IPS=(192.168.1.101 192.168.1.104) # CHANGE THIS
KUBESPRAY_VERSION=$(get_latest_release "kubernetes-sigs/kubespray")
HELM_VERSION=$(get_latest_release "helm/helm")

# Step 1: Enable passwordless sudo and ensure connection on target servers with same username (a prompt for password might appear)
init_connections () {
  # Execute using the default user and make sure all app servers use the same default user
  if [ $(echo ${EUID}) = 0 ]; then
    echo -e "${RED}${BOLD}Current user is root, please change the user to the default user to proceed${RESET}"
    exit 1
  fi
  echo -e "${BLUE}Your user is ${USER}, make sure that all servers have the same user with the same password${RESET}"
  # Check connectivity between servers using netcat
  for CLUSTER_NODE_IP in ${CLUSTER_NODES_IPS[@]}; do
    nc -z -v ${CLUSTER_NODE_IP} ${SSH_PORT} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo -e "${BLUE}Deployment server can ssh to ${CLUSTER_NODE_IP}${RESET}"
    else
      echo -e "${RED}${BOLD}Deployment server can't ssh to ${CLUSTER_NODE_IP}, please check connectivity and proper IP assignemnt${RESET}"
      exit 1
    fi
  done
  # Generate ssh keys on main server
  if [ ! -f ~/.ssh/admin-k8s ]; then
    ssh-keygen -q -t ed25519 -C "admin-k8s" -f ~/.ssh/admin-k8s -N ""
    cat ~/.ssh/admin-k8s.pub >> ~/.ssh/authorized_keys
  fi
  eval $(ssh-agent -s)
  ssh-add ~/.ssh/admin-k8s
  for CLUSTER_NODE_IP in ${CLUSTER_NODES_IPS[@]}
  do
    ssh-keyscan -H "${CLUSTER_NODE_IP}" >>  ~/.ssh/known_hosts
    # Enable passwordless sudo on servers
    ssh -t ${USER}@${CLUSTER_NODE_IP} "if sudo cat /etc/sudoers | grep -q "NOPASSWD"; then \
    echo "user ${USER} has passwordless sudo privilges on the server with IP ${CLUSTER_NODE_IP}"; else \
    echo '%sudo  ALL=(ALL) NOPASSWD:ALL' | sudo EDITOR='tee -a' visudo; fi"
    ssh-keyscan -H ${CLUSTER_NODE_IP} >> /home/${USER}/.ssh/known_hosts
    ssh-copy-id -i ~/.ssh/admin-k8s ${CLUSTER_NODE_IP}
  done
}

# Step 2: Install dependencies and NTP on all servers and disable swap and ufw
download_dependencies () {
  # Check https://discuss.kubernetes.io/t/swap-off-why-is-it-necessary/6879 if you're not sure why
  for CLUSTER_NODE_IP in ${CLUSTER_NODES_IPS[@]}; do
    ssh -t ${USER}@${CLUSTER_NODE_IP} "sudo apt-get update && \
    sudo apt-get upgrade -y && \
    sudo apt-get install git python3 net-tools ntp python3-pip python3-venv -y && \
    sudo systemctl enable ntp || true && \
    sudo systemctl start ntp && \
    sudo swapoff -a && \
    sudo ufw disable"
  done
}

# Step 3: Prepare Kubespray and install Kubernetes
setup_kubespray () {
  # Check if repo is already cloned or not
  if [ -d "${KUBESPRAY_SRC_DIR}" ]; then
    echo -e "${BLUE}Kubespray already exists, proceeding with next step${RESET}"
  else
    # Clone repo and switch to latest stable release tag
    cd /usr/local/src && sudo git clone https://github.com/kubernetes-sigs/kubespray.git "${KUBESPRAY_SRC_DIR}"
    sudo chown -R ${USER}:${USER} "${KUBESPRAY_SRC_DIR}"
    cd ${KUBESPRAY_SRC_DIR}
    git checkout tags/${KUBESPRAY_VERSION}
    cd ..
    sudo chown -R ${USER}:${USER} "${KUBESPRAY_SRC_DIR}"
  fi
  # Download Kubespray dependencies
  local inventory_builder="${KUBESPRAY_SRC_DIR}"/contrib/inventory_builder
  python3 -m venv "${PYTHON_ENV_DIR}" && source "${PYTHON_ENV_DIR}"/bin/activate
  pip install -r "${KUBESPRAY_SRC_DIR}"/requirements.txt -r "${inventory_builder}"/requirements.txt
  # Create cluster directory
  cp -rfp "${KUBESPRAY_SRC_DIR}"/inventory/sample "${KUBESPRAY_SRC_DIR}"/inventory/mycluster
  local nodes_count=$(echo "${#CLUSTER_NODES_IPS[@]}")
  # Prepare Ansible Inventory file using inventory builder python script
  echo -e "${BLUE}Preparing the inventory file for ${nodes_count} nodes${RESET}"
  KUBE_MASTERS="${nodes_count}" \
  CONFIG_FILE="${KUBESPRAY_SRC_DIR}"/inventory/mycluster/hosts.yml \
  python3 "${inventory_builder}"/inventory.py "${CLUSTER_NODES_IPS[@]}"
  install_kubernetes
  # Exit Python venv
  deactivate
}

# Step 4: Install latest version of Helm and Nginx ingress controller
install_ingress_controller () {
  # Downloads latest version of Helm
  install_helm
  cat << EOF > nginx-controller-values.yml
controller:
  kind: daemonset
  hostNetwork: true
  service:
    create: false
  config:
    entries:
      worker-processes: "8"
      worker-rlimit-nofile: "523264"
      worker-connections: "163840"
      proxy-connect-timeout: "120"
      proxy-read-timeout: "120"
      proxy-send-timeout: "120"
  initContainers:
  - name: "sysctl"
    image: "alpine"
    securityContext:
      privileged: true
    command: ["sh", "-c", "sysctl -w net.core.somaxconn=327680; sysctl -w net.ipv4.ip_local_port_range='1024 65000'"]
EOF
  # Install Ingress Controller
  sudo su -c "kubectl create namespace nginx-ingress"
  sudo su -c "helm upgrade -i -n nginx-ingress nginx-ingress oci://ghcr.io/nginxinc/charts/nginx-ingress -f nginx-controller-values.yml"
}

# Main function
main() {
  echo -e "\n${BLUE}${BOLD}█▒▒▒▒ INIT CONNECTIONS ▒▒▒▒█${RESET}\n"
  init_connections
  echo -e "\n${BLUE}${BOLD}██▒▒▒ DOWNLOADING DEPENDENCIES ▒▒▒██${RESET}\n"
  download_dependencies
  echo -e "\n${BLUE}${BOLD}███▒▒ SETTING UP KUBESPRAY ▒▒███${RESET}\n"
  setup_kubespray
  echo -e "\n${BLUE}${BOLD}████▒ INSTALLING KUBERNETES ▒████${RESET}\n"
  install_ingress_controller
  echo -e "\n${BLUE}${BOLD}█████ KUBERNETES HAS BEEN INSTALLED SUCCESSFULLY █████${RESET}\n"
}

main