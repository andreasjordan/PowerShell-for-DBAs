#!/bin/bash

# https://docs.microsoft.com/de-de/powershell/scripting/install/install-ubuntu

apt-get install -y wget apt-transport-https software-properties-common && \
wget -q -O /tmp/packages-microsoft-prod.deb "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" && \
dpkg -i /tmp/packages-microsoft-prod.deb && \
apt-get update && \
apt-get install -y powershell && \
echo 'OK'
