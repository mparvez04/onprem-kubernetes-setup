# Installing the Client Tools
Generate SSH key pair on controlplane01 node:

```
ssh-keygen
```

Add this key to the local authorized_keys (controlplane01)

``` 
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

```
# ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@controlplane01
# ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@controlplane02
# ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@loadbalancer
# ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@node01
# ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@node02
```

`$(whoami)` selects the appropriate user name

## Install kubectl

```
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
# chmod +x kubectl
# sudo mv kubectl /usr/local/bin/
```

## Verification

```
# kubectl version --client
```

## Provisioning Self-signed CA and Generating Certificates

```
# bash kubernetes_cert.sh
```

## Generating Kubernetes Configuration Files for Authentication

```
## bash kubernetes_config.sh
```

## Generating the Data Encryption Config and Key

```
## bash kubernetes_encry.sh
```

## Bootstrapping the etcd Cluster

[Follow KodeKloud ETCD Doc](https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md)

## Setup Kubernetes Control Plane, API Server, Scheduler and Load Balancer

[Follow KodeKloud ControlPlane Doc](https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md)

## CRI and CNI for worker nodes (controlplane01, controlplane02, node01, node02)

[Follow KodeKloud Worker Nodes Doc](https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/09-install-cri-workers.md)

## Bootstrapping the Kubernetes Worker Nodes

Already create certificate and kube config files using `kubernetes_cert.sh` and `kubernetes_config.sh`

Using iterm2 run those below command in parrallel of those nodes (controlplane01, controlplane02, node01, node02) 

## Download and Install Worker Binaries
```
KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

# wget -q --show-progress --https-only --timestamping \
  https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-proxy \
  https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kubelet 

# {
  chmod +x kube-proxy kubelet
  sudo mv kube-proxy kubelet /usr/local/bin/
}
```
## Create the installation directories:
```
sudo mkdir -p \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes/pki \
  /var/run/kubernetes
```

## Setting up Kubelet

```
{
  sudo mv ${HOSTNAME}.key ${HOSTNAME}.crt /var/lib/kubernetes/pki/
  sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubelet.kubeconfig
  sudo mv ca.crt /var/lib/kubernetes/pki/
  sudo mv kube-proxy.crt kube-proxy.key /var/lib/kubernetes/pki/
  sudo chown root:root /var/lib/kubernetes/pki/*
  sudo chmod 600 /var/lib/kubernetes/pki/*
  sudo chown root:root /var/lib/kubelet/*
  sudo chmod 600 /var/lib/kubelet/*
}
```

## CIDR ranges and cluster DNS address used within the cluster
```
POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/16
CLUSTER_DNS=$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.10", $1, $2, $3) }')
```

## Create the kubelet.service file

```
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --kubeconfig=/var/lib/kubelet/kubelet.kubeconfig \\
  --node-ip=${PRIMARY_IP} \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```
## Kubernetes Proxy
```
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/
```
## Generate kube-proxy-config.yaml file
```
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: /var/lib/kube-proxy/kube-proxy.kubeconfig
mode: iptables
clusterCIDR: ${POD_CIDR}
EOF
```
## Generate kube-proxy.service file

```
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

## Start the Worker Services

```
{
  sudo systemctl daemon-reload
  sudo systemctl enable kubelet kube-proxy
  sudo systemctl start kubelet kube-proxy
}
```

## Verify the cluster from controlplane01

```
kubectl get nodes --kubeconfig admin.kubeconfig
```

## Provisioning Pod Network

[Follow KodeKloud Pod Network - Weave Doc](https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/13-configure-pod-networking.md)

## RBAC for Kubelet Authorization

[API to Kubelet](https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/14-kube-apiserver-to-kubelet.md)

## Deploying the DNS Cluster Add-on
[core-dns](https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/15-dns-addon.md)

## Install CLI and validation tools for Kubelet Container Runtime Interface (CRI)
```
# sudo apt install cri-tools
```