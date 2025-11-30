#!/usr/bin/env bash

# Kubernetes cluster configuration variables
CONTROL01=$(dig +short controlplane01)
CONTROL02=$(dig +short controlplane02)
LOADBALANCER=$(dig +short loadbalancer)
NODE01=$(dig +short node01)
NODE02=$(dig +short node02)

SERVICE_CIDR=10.96.0.0/24
API_SERVICE=$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.1", $1, $2, $3) }')

# Self-signing certificate, Function to generate a Certificate Authority (CA)
function generate_ca() {
  # Create private key for CA
  openssl genrsa -out ca.key 2048

  # Create CSR using the private key
  openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA/O=Kubernetes" -out ca.csr

  # Self sign the csr using its own private key
  openssl x509 -req -in ca.csr -signkey ca.key -CAcreateserial -out ca.crt -days 1000
}

# Client and Server Certificates
# Generate the admin client certificate and private key:

function generate_admin_cert() {
  # Generate private key for admin user
  openssl genrsa -out admin.key 2048

  # Generate CSR for admin user. Note the OU.
  openssl req -new -key admin.key -subj "/CN=admin/O=system:masters" -out admin.csr

  # Sign certificate for admin user using CA servers private key
  openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out admin.crt -days 1000
}

# The Kubelet Client Certificates

function generate_kubelet_cert() {
  for NODE in ${CONTROL01} ${CONTROL02} ${NODE01} ${NODE02}; do
    if [ ${NODE} == "192.168.64.2" ]; then
      NODENAME="controlplane01"
    elif [ ${NODE} == "192.168.64.3" ]; then
      NODENAME="controlplane02"
    elif [ ${NODE} == "192.168.64.5" ]; then
      NODENAME="node01"
    elif [ ${NODE} == "192.168.64.6" ]; then
      NODENAME="node02"
    fi
    # Create OpenSSL config file for each kubelet
    cat > openssl-${NODENAME}.cnf <<EOF
    [req]
    request_extensions = v3_req
    distinguished_name = req_distinguished_name
    [req_distinguished_name]
    [v3_req]
    keyUsage = nonRepudiation, digitalSignature, keyEncipherment
    subjectAltName = @alt_names
    [alt_names]
    DNS.1 = ${NODENAME}
    IP.1 = ${NODE}
EOF
    # Generate private key for kubelet
    openssl genrsa -out ${NODENAME}.key 2048
    openssl req -new -key ${NODENAME}.key -subj "/CN=system:node:${NODENAME}/O=system:nodes" -out ${NODENAME}.csr -config openssl-${NODENAME}.cnf
    openssl x509 -req -in ${NODENAME}.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out ${NODENAME}.crt -extensions v3_req -extfile openssl-${NODENAME}.cnf -days 1000
  done
}

# Generate the kube-controller-manager client certificate and private key

function generate_kube_controller_manager_cert() {
  openssl genrsa -out kube-controller-manager.key 2048

  openssl req -new -key kube-controller-manager.key \
    -subj "/CN=system:kube-controller-manager/O=system:kube-controller-manager" -out kube-controller-manager.csr

  openssl x509 -req -in kube-controller-manager.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-controller-manager.crt -days 1000
}

# Generate the kube-proxy client certificate and private key
function generate_kube_proxy_cert() {
  openssl genrsa -out kube-proxy.key 2048

  openssl req -new -key kube-proxy.key \
    -subj "/CN=system:kube-proxy/O=system:node-proxier" -out kube-proxy.csr

  openssl x509 -req -in kube-proxy.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-proxy.crt -days 1000
}

# Generate the kube-scheduler client certificate and private key
function generate_kube_scheduler_cert() {
  openssl genrsa -out kube-scheduler.key 2048

  openssl req -new -key kube-scheduler.key \
    -subj "/CN=system:kube-scheduler/O=system:kube-scheduler" -out kube-scheduler.csr

  openssl x509 -req -in kube-scheduler.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-scheduler.crt -days 1000
}

# Generate the kube-apiserver server certificate and private key
function generate_kube_apiserver_cert() {
cat > openssl-kube-apiserver.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = ${API_SERVICE}
IP.2 = ${CONTROL01}
IP.3 = ${CONTROL02}
IP.4 = ${LOADBALANCER}
IP.5 = 127.0.0.1
EOF

  openssl genrsa -out kube-apiserver.key 2048

  openssl req -new -key kube-apiserver.key \
    -subj "/CN=kube-apiserver/O=Kubernetes" -out kube-apiserver.csr -config openssl-kube-apiserver.cnf

  openssl x509 -req -in kube-apiserver.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-apiserver.crt -extensions v3_req -extfile openssl-kube-apiserver.cnf -days 1000
}

# Generate the kube-apiserver-kubelet-client certificate and private key
function generate_apiserver_kubelet_client_cert() {
cat > openssl-kubelet.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

  openssl genrsa -out apiserver-kubelet-client.key 2048

  openssl req -new -key apiserver-kubelet-client.key \
    -subj "/CN=kube-apiserver-kubelet-client/O=system:masters" -out apiserver-kubelet-client.csr -config openssl-kubelet.cnf

  openssl x509 -req -in apiserver-kubelet-client.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial -out apiserver-kubelet-client.crt -extensions v3_req -extfile openssl-kubelet.cnf -days 1000
}

# Generate the etcd server certificate and private key
function generate_etcd_server_cert() {
cat > openssl-etcd.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = ${CONTROL01}
IP.2 = ${CONTROL02}
IP.3 = 127.0.0.1
EOF

  openssl genrsa -out etcd-server.key 2048

  openssl req -new -key etcd-server.key \
    -subj "/CN=etcd-server/O=Kubernetes" -out etcd-server.csr -config openssl-etcd.cnf

  openssl x509 -req -in etcd-server.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial -out etcd-server.crt -extensions v3_req -extfile openssl-etcd.cnf -days 1000
}

# Generate the service account certificate and private key
function generate_service_account_cert() {
  openssl genrsa -out service-account.key 2048

  openssl req -new -key service-account.key \
    -subj "/CN=service-accounts/O=Kubernetes" -out service-account.csr

  openssl x509 -req -in service-account.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial -out service-account.crt -days 1000
}

# Distribute the generated certificates and keys to respective nodes
function distribute_certs() {
for instance in controlplane02; do
  scp -o StrictHostKeyChecking=no ca.crt ca.key kube-apiserver.key kube-apiserver.crt \
    apiserver-kubelet-client.crt apiserver-kubelet-client.key \
    service-account.key service-account.crt \
    etcd-server.key etcd-server.crt \
    kube-proxy.crt kube-proxy.key \
    ${instance}.crt ${instance}.key \
    kube-controller-manager.key kube-controller-manager.crt \
    kube-scheduler.key kube-scheduler.crt \
    ${instance}:~/
done

for instance in node01 node02 ; do
  scp ca.crt kube-proxy.crt kube-proxy.key  ${instance}.crt ${instance}.key ${instance}:~/
done
}

# Execute all functions to generate certificates
echo "Generating Kubernetes certificates and keys..."
echo "CA certificate and key generated."
generate_ca

echo "Admin certificate and key generated."
generate_admin_cert

echo "Kubelet certificates and keys generated."
generate_kubelet_cert

echo "Kube-controller-manager certificate and key generated."
generate_kube_controller_manager_cert

echo "Kube-proxy certificate and key generated."
generate_kube_proxy_cert

echo "Kube-scheduler certificate and key generated."
generate_kube_scheduler_cert

echo "Kube-apiserver certificate and key generated."
generate_kube_apiserver_cert

echo "Kube-apiserver-kubelet-client certificate and key generated."
generate_apiserver_kubelet_client_cert

echo "Etcd server certificate and key generated."
generate_etcd_server_cert

echo "Service account certificate and key generated."
generate_service_account_cert
echo "All certificates and keys have been generated successfully."

# Distribute the certificates to respective nodes
echo "Distributing certificates to cluster nodes..."
distribute_certs
echo "Certificates distributed successfully."