#!/bin/bash

# 01_setup_DNS.sh
echo "[network]" >> /etc/wsl.conf && \
echo "generateResolvConf = false" >> /etc/wsl.conf && \
rm /etc/resolv.conf && \
echo "nameserver 1.1.1.1" > /etc/resolv.conf && \
# 02_update_packages.sh
apt update && \
apt -y upgrade && \
# 03_install_pwsh.sh
apt-get install -y wget apt-transport-https software-properties-common && \
wget -q -O /tmp/packages-microsoft-prod.deb "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" && \
dpkg -i /tmp/packages-microsoft-prod.deb && \
apt-get update && \
apt-get install -y powershell && \
# 05_install_docker.sh
apt-get install -y ca-certificates curl gnupg2 lsb-release && \
mkdir -p /etc/apt/keyrings && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
apt update && \
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin && \
update-alternatives --set iptables /usr/sbin/iptables-legacy && \
service docker start && \
# 06_setup_docker.sh
docker pull mcr.microsoft.com/mssql/server:2019-latest && \
docker pull container-registry.oracle.com/database/express:latest && \
echo 'OK'
