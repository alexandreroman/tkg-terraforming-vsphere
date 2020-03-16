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

# Install krew plugins: ctx, ns.
if ! [ -d /home/ubuntu/.krew ]; then
  (
    set -x; cd "$(mktemp -d)" &&
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.{tar.gz,yaml}" &&
    tar zxvf krew.tar.gz &&
    KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" &&
    "$KREW" install --manifest=krew.yaml --archive=krew.tar.gz &&
    "$KREW" update
  )
  echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> /home/ubuntu/.bashrc
  source /home/ubuntu/.bashrc
  kubectl krew update
  kubectl krew install ctx
  kubectl krew install ns
fi

# Generate a default TKG configuration
# (this command will fail but it's normal at this point).
if ! [ -f /home/ubuntu/.tkg/config.yaml ]; then
  tkg init -q
fi

# Configure TKG.
if [ -f /home/ubuntu/tkg-cluster.yml ]; then
  cat /home/ubuntu/tkg-cluster.yml >> /home/ubuntu/.tkg/config.yaml
  SSH_PUBLIC_KEY=`cat /home/ubuntu/.ssh/id_rsa.pub`
  cat <<EOF >> /home/ubuntu/.tkg/config.yaml
VSPHERE_SSH_AUTHORIZED_KEY: "$SSH_PUBLIC_KEY"
EOF
  sed -i 's/KUBERNETES_VERSION: 1.16.2/KUBERNETES_VERSION: 1.17.3/g' /home/ubuntu/.tkg/config.yaml
  /bin/rm -f /home/ubuntu/tkg-cluster.yml
fi
