#!/bin/sh

# Uncompress TKG archive and install CLI.
if [ -f /home/ubuntu/tkg.gz ]; then
  cd /home/ubuntu && gunzip /home/ubuntu/tkg.gz && \
    chmod +x /home/ubuntu/tkg && \
    sudo mv /home/ubuntu/tkg /usr/local/bin
fi

# Generate a SSH keypair.
if ! [ -f /home/ubuntu/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -f /home/ubuntu/.ssh/id_rsa -q -P ''
fi

# Install K8s CLI.
if ! [ -f /usr/local/bin/kubectl ]; then
  K8S_VERSION=v1.17.0
  curl -LO https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    sudo mv ./kubectl /usr/local/bin/kubectl
    echo 'source <(kubectl completion bash)' >>~/.bashrc
fi

# Generate a default TKG configuration.
if ! [ -f /home/ubuntu/.tkg/config.yaml ]; then
  tkg get mc
fi

# Configure TKG.
if [ -f /home/ubuntu/tkg-cluster.yml ]; then
  cat /home/ubuntu/tkg-cluster.yml >> /home/ubuntu/.tkg/config.yaml
  SSH_PUBLIC_KEY=`cat /home/ubuntu/.ssh/id_rsa.pub`
  cat <<EOF >> /home/ubuntu/.tkg/config.yaml
VSPHERE_SSH_AUTHORIZED_KEY: "$SSH_PUBLIC_KEY"
EOF
  /bin/rm -f /home/ubuntu/tkg-cluster.yml
fi
