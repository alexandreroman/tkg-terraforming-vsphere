#!/bin/sh

. /home/ubuntu/.env

# Set up HTTP proxy support
if ! [ -z "$HTTP_PROXY_HOST" ]; then
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

if [ -f /home/ubuntu/tanzu-cli.tar.gz ]; then
  cd /home/ubuntu && gunzip /home/ubuntu/tanzu-cli.tar.gz
fi

# Uncompress TKG archive and install CLI.
if [ -f /home/ubuntu/tanzu-cli.tar ]; then
  mkdir /home/ubuntu/tanzu && mv /home/ubuntu/tanzu-cli.tar /home/ubuntu/tanzu && \
    cd /home/ubuntu/tanzu && tar vxf tanzu-cli.tar && cd /home/ubuntu/tanzu/cli && \
    sudo install core/v*/tanzu-core-linux_amd64 /usr/local/bin/tanzu && \
    gunzip ytt-linux-amd64-*.gz && sudo install ytt-linux-amd64* /usr/local/bin/ytt && \
    gunzip kapp-linux-amd64*.gz && sudo install kapp-linux-amd64* /usr/local/bin/kapp && \
    gunzip imgpkg-linux-amd64*.gz && sudo install imgpkg-linux-amd64* /usr/local/bin/imgpkg && \
    gunzip kbld-linux-amd64*.gz && sudo install kbld-linux-amd64* /usr/local/bin/kbld && \
    gunzip vendir-linux-amd64*.gz && sudo install vendir-linux-amd64* /usr/local/bin/vendir && \
    tanzu init && \
    tanzu plugin clean

    # For TKG 1.4 and earlier:
    tanzu plugin install --local /home/ubuntu/tanzu/cli all

    # For TKG 1.5+:
    cd /home/ubuntu/tanzu && tanzu plugin sync

    cd /home/ubuntu && mkdir -p /home/ubuntu/.config/tanzu && \
    tanzu completion bash > /home/ubuntu/.config/tanzu/completion.bash.inc && \
    printf "\n# Tanzu shell completion\nsource '/home/ubuntu/.config/tanzu/completion.bash.inc'\n" >> ~/.bashrc
fi

# Uncompress TCE archive and install CLI.
if [ -f /home/ubuntu/tce.tar.gz ]; then
  mkdir /home/ubuntu/tanzu && mv /home/ubuntu/tce.tar.gz /home/ubuntu/tanzu && \
    cd /home/ubuntu/tanzu && tar --strip-components=1 -zxvf tce.tar.gz && \
    ./install.sh && \
    mkdir -p /home/ubuntu/.config/tanzu && \
    tanzu completion bash > /home/ubuntu/.config/tanzu/completion.bash.inc && \
    printf "\n# Tanzu shell completion\nsource '/home/ubuntu/.config/tanzu/completion.bash.inc'\n" >> ~/.bashrc
fi

# Generate a default TKG configuration.
if ! [ -f /home/ubuntu/.config/tanzu/tkg/clusterconfigs/mgmt-cluster-config.yaml ]; then
  tanzu config init > /dev/null 2>&1
  mkdir -p ~/.config/tanzu/tkg/clusterconfigs
  cat <<EOF >> ~/.config/tanzu/tkg/clusterconfigs/mgmt-cluster-config.yaml
CLUSTER_NAME: mgmt
CLUSTER_PLAN: dev
VSPHERE_CONTROL_PLANE_ENDPOINT: "$CONTROL_PLANE_ENDPOINT"
EOF
fi

# Generate a SSH keypair.
if ! [ -f /home/ubuntu/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -f /home/ubuntu/.ssh/id_rsa -q -P ''
fi

# Install K8s CLI.
if ! [ -f /usr/local/bin/kubectl ]; then
  K8S_VERSION=v1.22.9
  curl -LO https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    sudo install ./kubectl /usr/local/bin/kubectl && \
    rm ./kubectl
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
fi

# Install govc.
if ! [ -f /usr/local/bin/govc ]; then
  curl -L https://github.com/vmware/govmomi/releases/download/v0.20.0/govc_linux_amd64.gz | gunzip -c > /tmp/govc && \
    sudo install /tmp/govc /usr/local/bin/govc
  cat ~/.govc.env >> ~/.bashrc
fi

# Configure TKG.
if [ -f /home/ubuntu/tkg-cluster.yml ]; then
  cat /home/ubuntu/tkg-cluster.yml >> ~/.config/tanzu/tkg/config.yaml
  SSH_PUBLIC_KEY=`cat /home/ubuntu/.ssh/id_rsa.pub`
  cat <<EOF >> ~/.config/tanzu/tkg/config.yaml
VSPHERE_SSH_AUTHORIZED_KEY: "$SSH_PUBLIC_KEY"
EOF
  /bin/rm -f /home/ubuntu/tkg-cluster.yml
fi

# Install yq.
sudo snap install yq

# Configure VIm.
if ! [ -f /home/ubuntu/.vimrc ]; then
  cat <<EOF >> /home/ubuntu/.vimrc
filetype plugin indent on
syntax on
set term=xterm-256color

set ai
set et
set ts=2
set sw=2
set ruler
set cursorcolumn
EOF
fi

# Install Docker.
sudo apt-get update && \
sudo apt-get -y install docker.io && \
sudo ln -sf /usr/bin/docker.io /usr/local/bin/docker && \
sudo usermod -aG docker ubuntu

# Install K9s.
if ! [ -f /usr/local/bin/k9s ]; then
  mkdir /home/ubuntu/k9s && \
  cd /home/ubuntu/k9s && \
  curl -L https://github.com/derailed/k9s/releases/download/v0.25.18/k9s_Linux_x86_64.tar.gz -o k9s.tar.gz && \
  tar zxf k9s.tar.gz && \
  sudo install ./k9s /usr/local/bin/k9s && \
  cd /home/ubuntu && \
  rm -rf /home/ubuntu/k9s
  echo 'export COLORTERM=truecolor' >> ~/.bashrc
fi

# Install kubectx.
if ! [ -f /usr/local/bin/kubectx ]; then
  curl -L https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubectx_v0.9.4_linux_x86_64.tar.gz -o /home/ubuntu/kubectx.tar.gz && \
  tar zxf /home/ubuntu/kubectx.tar.gz && \
  sudo install /home/ubuntu/kubectx /usr/local/bin/kubectx && \
  rm /home/ubuntu/kubectx /home/ubuntu/kubectx.tar.gz
fi
