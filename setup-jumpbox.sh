#!/bin/sh

. /home/ubuntu/.env

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

# Generate a default TKG configuration.
if ! [ -f /home/ubuntu/.tkg/config.yaml ]; then
  tkg get mc
fi

# Set up HTTP proxy support
if ! [ -z "HTTP_PROXY_HOST" ]; then
  export http_proxy=http://${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}
  export https_proxy=http://${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}
  export NO_PROXY=localhost,127.0.0.1,.svc,.local

  cat <<EOF >> /home/ubuntu/apt-proxy
Acquire {
  HTTP::proxy "http://${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}";
  HTTPS::proxy "http://${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}";
}
EOF
  sudo mv /home/ubuntu/apt-proxy /etc/apt/apt.conf.d/proxy
  sudo snap set system proxy.http="http://${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}"
  sudo snap set system proxy.https="http://${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}"

  cat <<EOF >> /home/ubuntu/docker-proxy
[Service]
Environment="HTTP_PROXY=http://${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}"
Environment="HTTPS_PROXY=http://${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}"
Environment="NO_PROXY="localhost,127.0.0.1,::1,.local"
EOF
  sudo mkdir -p /etc/systemd/system/docker.service.d
  sudo mv /home/ubuntu/docker-proxy /etc/systemd/system/docker.service.d/proxy.conf
fi

# Generate a SSH keypair.
if ! [ -f /home/ubuntu/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -f /home/ubuntu/.ssh/id_rsa -q -P ''
fi

# Install K8s CLI.
if ! [ -f /usr/local/bin/kubectl ]; then
  K8S_VERSION=v1.19.3
  curl -LO https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    sudo mv ./kubectl /usr/local/bin/kubectl
    echo 'source <(kubectl completion bash)' >>~/.bashrc
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
