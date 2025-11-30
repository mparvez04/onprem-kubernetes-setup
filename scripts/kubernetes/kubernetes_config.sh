#!/usr/bin/env bash

LOADBALANCER=$(dig +short loadbalancer)

# Function to generate kubeconfig for the kube-proxy component
function generate_kube_proxy_conf() {
  kubectl config set-cluster kubernetes-on-mac \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://${LOADBALANCER}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=/var/lib/kubernetes/pki/kube-proxy.crt \
    --client-key=/var/lib/kubernetes/pki/kube-proxy.key \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-on-mac \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}

# Function to generate kubeconfig for the kube-controller-manager component
function generate_kube_controller_manager_conf() {
  kubectl config set-cluster kubernetes-on-mac \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=/var/lib/kubernetes/pki/kube-controller-manager.crt \
    --client-key=/var/lib/kubernetes/pki/kube-controller-manager.key \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-on-mac \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}


# Function to generate kubeconfig for the kube-scheduler component
function generate_kube_scheduler_conf() {
  kubectl config set-cluster kubernetes-on-mac \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=/var/lib/kubernetes/pki/kube-scheduler.crt \
    --client-key=/var/lib/kubernetes/pki/kube-scheduler.key \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-on-mac \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}

function generate_nodes_kubeconfig() {
for instance in controlplane01 controlplane02 node01 node02; do
  kubectl config set-cluster kubernetes-on-mac \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://${LOADBALANCER}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=/var/lib/kubernetes/pki/${instance}.crt \
    --client-key=/var/lib/kubernetes/pki/${instance}.key \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-on-mac \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done
}

# Function to generate kubeconfig for the admin user
function generate_admin_conf() {
  kubectl config set-cluster kubernetes-on-mac \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-on-mac \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig
}

# Function to distribute certificates to cluster nodes
function distribute_certs() {
for instance in node01 node02 controlplane02; do
  scp admin.kubeconfig kube-proxy.kubeconfig ${instance}.kubeconfig ${instance}:~/
done
for instance in controlplane02; do
  scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done
}

# Generate all kubeconfig files
echo "Generating kubeconfig files..."

# Generate kubeconfig files for proxy
echo "Generating kube-proxy kubeconfig..."
generate_kube_proxy_conf

# Generate kubeconfig files for controller manager
echo "Generating kube-controller-manager kubeconfig..."
generate_kube_controller_manager_conf

# Generate kubeconfig files for scheduler
echo "Generating kube-scheduler kubeconfig..."
generate_kube_scheduler_conf

# Generate kubeconfig files for nodes
echo "Generating nodes kubeconfig files..."
generate_nodes_kubeconfig

# Generate kubeconfig file for admin user
echo "Generating admin kubeconfig..."
generate_admin_conf

echo "Kubeconfig files generated successfully."

# Distribute the kubeconfig files to respective nodes
echo "Distributing kubeconfig files to cluster nodes..."
distribute_certs
echo "Kubeconfig files distributed successfully."