#!/bin/bash

# https://docs.docker.com/engine/install/ubuntu/

sudo apt-get install -y ca-certificates curl gnupg2 lsb-release && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
sudo apt update && \
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin && \
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy && \
sudo service docker start && \
echo 'OK'
