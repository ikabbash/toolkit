# toolkit

Personal scripts and assets.

## Scripts

```
scripts
├── azure
│   ├── bastion-tunnel.sh
│   ├── get-deallocated-disks.sh
│   ├── get-running-vms.sh
│   └── README.md
├── bash
│   └── kubernetes
│       ├── get-logs.sh
│       └── kubespray
│           ├── init-k8s.sh
│           ├── nginx-test.yaml
│           └── README.md
└── python
    └── image-to-text.py

6 directories, 9 files
```

### Azure

- `bastion-tunnel.sh`: Creates an SSH bastion tunnel for Azure VMs.
- `get-deallocated-disks.sh`: Lists all deallocated Azure managed disks.
- `get-running-vms.sh`: Lists all running Azure VMs with details (name, region, size, OS, disk info).

### Bash / Kubernetes

- `get-logs.sh`: Fetches logs from all pods in specified namespaces (or `all`) and saves them to `kube-logs-<timestamp>/`.
- `init-k8s.sh`: Installs a Kubernetes cluster using Kubespray, including Helm and NGINX Ingress Controller.

### Python

- `image-to-text.py`: Extracts text from images using Tesseract OCR.
