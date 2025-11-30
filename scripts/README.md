# Prerequisite  VMs Setup for Kubernetes Cluster on Apple Silicon

## Hardware Requirements

This lab provisions 5 VMs on your workstation. That's a lot of compute resource!

Laptop Used
* Chip -> Apple M4
* Memory 24GB

## List of Servers
| Server | Memory | CPU | Disk |
| --- | --- | --- | --- |
| controlplane01 | 2GB | 2 | 10GB|
| controlplane02 | 2GB | 2 | 10GB|
| loadbalancer | 512MB | 1 | 5GB|
| node01 | 2GB | 2 | 10GB|
| node01 | 2GB | 2 | 10GB|

run the below script to deploy VMs:

```
# bash ./deploy-vms-multipass.sh 
```

[Refactor the script to meet my requirements](https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/apple-silicon/deploy-virtual-machines.sh)

run the below command to verify VMs:

```
# multipass list
```

[Running Commands in Parallel with iterm2](https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/apple-silicon/docs/01-prerequisites.md)

run this below command to install iterm2:

```
# brew install iterm2
```

[!CAUTION] run the below script to delete VMs:

```
bash ./multipass-delete-vms.sh
```
