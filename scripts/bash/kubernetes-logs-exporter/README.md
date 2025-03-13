# Kubernetes Logs Exporter

This directory contains two scripts:

- The `get-logs-ns.sh` script exports logs for all pods in a specified namespace, saving each pod's logs into a separate file within a directory.
    - Give namespace name as an argument to the script: `./get-logs-ns.sh <namespace-name>`.
- The `get-logs-all.sh` script exports logs for all pods in every namespace, organizing them into directories with the following structure:
    ```
    kube-logs-DD-MM-YYYY_HH-MM/
    │-- namespace-1/
    │   ├── pod1.log
    │   ├── pod2.log
    │-- namespace-2/
    │   ├── podA.log
    │   ├── podB.log
    ```
