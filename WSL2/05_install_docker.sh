#!/bin/bash

# https://docs.docker.com/engine/install/ubuntu/

apt-get install -y ca-certificates curl gnupg2 lsb-release && \
mkdir -p /etc/apt/keyrings && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
apt update && \
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin && \
update-alternatives --set iptables /usr/sbin/iptables-legacy && \
service docker start && \
echo 'OK'
