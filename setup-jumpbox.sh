#!/bin/sh

# Uncompress TKG archive and install CLI.
if [ -f /home/ubuntu/tkg.tgz ]; then
  cd /home/ubuntu && tar zxf /home/ubuntu/tkg.tgz && \
    chmod +x /home/ubuntu/tkg/* && \
    sudo mv /home/ubuntu/tkg/tkg* /usr/local/bin/tkg && \
    sudo mv /home/ubuntu/tkg/imgpkg* /usr/local/bin/imgpkg && \
    sudo mv /home/ubuntu/tkg/kapp* /usr/local/bin/kapp && \
    sudo mv /home/ubuntu/tkg/kbld* /usr/local/bin/kbld && \
    sudo mv /home/ubuntu/tkg/ytt* /usr/local/bin/ytt && \
    rm -rf /home/ubuntu/tkg.tgz /home/ubuntu/tkg
fi

# Generate a SSH keypair.
if ! [ -f /home/ubuntu/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -f /home/ubuntu/.ssh/id_rsa -q -P ''
fi

# Install K8s CLI.
if ! [ -f /usr/local/bin/kubectl ]; then
  K8S_VERSION=v1.19.1
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

# Change cloning mechanism to linkedClone (from fullClone), in order to
# lower VM creation time and save disk space.
sed -i 's/fullClone/linkedClone/g' $HOME/.tkg/providers/infrastructure-vsphere/v*/cluster-template-*.yaml

# Install yq.
sudo snap install yq

# Configure VIm.
if ! [ -f /home/ubuntu/.vimrc ]; then
  cat <<EOF >> /home/ubuntu/.vimrc
set ts=2
set sw=2
set ai
set et
EOF
fi
