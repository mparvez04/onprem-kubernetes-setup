# onprem-kubernetes-setup
step by step setup for onprem kubernetes cluster in a secure enviroment

## Install Multipass
run this command:

```# brew install multipass```

It will run installer for multipass with `sudo` (which is going to request your root password)

run this command to verify installation:

```# multipass -h```

## To deploy and delete VMS follow this ReadME link below:
[VMs Setup for Kubernetes Cluster](scripts/README.md)

##  To increase the disk size of a Linux VM
⚠️ From 5GB to 10GB

run this command to verify the size of the disk for VM `node01`:
```
# multipass list
# multipass info node01
```
run this command to set the size of disk for VM `node01`:

```
# multipass stop node01
# multipass set local.node01.disk=10G
# multipass start node01
```

run this command to open shell of the VM `node01`:

```
# multipass shell node01
```

run this command to verify the size of the disk (/dev/sda) and partition (/dev/sda1) for VM `node01`:

```
# fdisk -l /dev/sda
```

run this command to resize the partition and filesystem of the VM `node01`:

```
# sudo parted /dev/sda resizepart 1 100%
```
