#!/bin/bash
set -euvx

install_unzip() {
  echo "Checking for unzip …"
  if command -v unzip >/dev/null 2>&1; then
    echo "unzip is already installed."
    unzip -v
  else
    echo "Installing unzip …"
    sudo apt-get update
    sudo apt-get install unzip -y
  fi
}
 
install_awscli() {
  echo "Checking for aws CLI …"
  if command -v aws >/dev/null 2>&1; then
    echo "AWS CLI is already installed." 
    aws --version
  else
    local TEMP_DIR_PATH=$(mktemp -d)
    cd ${TEMP_DIR_PATH}
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    cd
    rm -rf ${TEMP_DIR_PATH}
  fi
}
 
install_docker() {
  echo "Checking for docker …"
  if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed."
    docker --version
  else
    echo "Installing Docker prerequisites …"
    sudo apt-get update
    sudo apt-get install ca-certificates curl -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add the repository to Apt sources:
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin -y
  fi
}
 
install_mongosh() {
  echo "Checking for mongosh …"
  if command -v mongosh >/dev/null 2>&1; then
    echo "mongosh is already installed."
    mongosh --version
  else
    echo "Installing mongosh …"
    wget -qO- https://www.mongodb.org/static/pgp/server-8.0.asc | sudo tee /etc/apt/trusted.gpg.d/server-8.0.asc
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
    sudo apt-get update
    sudo apt-get install -y mongodb-mongosh
  fi
}
 
install_psql_client() {
  echo "Checking for psql …"
  if command -v psql >/dev/null 2>&1; then
    echo "psql is already installed."
    psql --version
  else 
    echo "Adding PostgreSQL APT repository …"
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
    sudo apt-get update
    sudo apt-get install postgresql-client-13 -y
  fi
}

install_kubectl() {
  echo "Checking kubectl …"
  if command -v kubectl >/dev/null 2>&1; then
    echo "kubectl is already installed."
    kubectl version --client
  else  
    echo "Downloading kubectl binary …"
    local version="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
    curl -LO "https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl"

    echo "Downloading kubectl checksum …"
    curl -LO "https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl.sha256"

    echo "Verifying checksum …"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

    echo "Installing kubectl …"
    chmod +x kubectl
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    echo "Setting up kubectl in user's local bin …"
    mkdir -p ~/.local/bin
    cp kubectl ~/.local/bin/

    echo "kubectl installed: $(kubectl version --client)"
  fi
}

install_eksctl() {
  echo "Checking eksctl …"
  if command -v eksctl >/dev/null 2>&1; then
    echo "eksctl is already installed."
    eksctl version
  else
    echo "Determining platform …"
    local ARCH=amd64
    local PLATFORM="$(uname -s)_${ARCH}"

    echo "Downloading eksctl …"
    curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz"

    echo "Verifying eksctl checksum …"
    curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | \
        grep "${PLATFORM}" | sha256sum --check

    echo "Extracting eksctl …"
    tar -xzf "eksctl_${PLATFORM}.tar.gz" -C /tmp
    rm "eksctl_${PLATFORM}.tar.gz"

    echo "Installing eksctl …"
    sudo install -m 0755 /tmp/eksctl /usr/local/bin/eksctl
    rm /tmp/eksctl

    echo "eksctl installed: $(eksctl version)"
  fi
}

install_yq() {
  echo "Checking yq …"
  if command -v yq >/dev/null 2>&1; then
    echo "yq is already installed."
    yq --version
  else
    echo "Installing yq …"
    sudo apt install yq
    echo "yq installed: $(yq --version)"
  fi
}

install_helm() {
  echo "Checking helm …"
  if command -v helm >/dev/null 2>&1; then
    echo "helm is already installed." 
    helm version --short
  else
    echo "Installing dependencies for Helm …"
    sudo apt-get update
    sudo apt-get install -y curl gpg apt-transport-https

    echo "Adding Helm APT repository …"
    curl -fsSL "https://packages.buildkite.com/helm-linux/helm-debian/gpgkey" | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | \
        sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

    echo "Installing Helm …"
    sudo apt-get update
    sudo apt-get install -y helm

    echo "helm installed: $(helm version --short)"
  fi
}

install_opentofu() {
  echo "Checking for OpenTofu …"
  if command -v tofu >/dev/null 2>&1; then
    echo "OpenTofu is already installed." 
    tofu version
  else
    echo "Installing OpenTofu …"
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    cd "${TMP_DIR}"

    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
    chmod +x install-opentofu.sh
    ./install-opentofu.sh --install-method deb
    cd ~
    rm -rf "${TMP_DIR}"
  fi
}

main() {
  install_unzip
  install_awscli
  install_docker
  install_mongosh
  install_psql_client
  install_kubectl
  install_eksctl
  install_yq
  install_helm
  install_opentofu
  echo "All installations completed."
}
 
main
exit ${?}
