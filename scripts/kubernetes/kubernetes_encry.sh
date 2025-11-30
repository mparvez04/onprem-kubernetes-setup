#!/usr/bin/env bash

# Generate a random encryption key for encrypting secrets
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

# Function to generate the encryption configuration file
function generate_encryption_config() {
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

for instance in controlplane02; do
  scp encryption-config.yaml ${instance}:~/
done

for instance in controlplane01 controlplane02; do
  ssh ${instance} sudo mkdir -p /var/lib/kubernetes/
  ssh ${instance} sudo mv encryption-config.yaml /var/lib/kubernetes/
done
}

# Call the function to generate the encryption configuration file
echo "Generating encryption configuration file..."
generate_encryption_config