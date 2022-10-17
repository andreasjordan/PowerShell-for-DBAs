#!/bin/bash

# Pull my favorite docker images

sudo docker pull mcr.microsoft.com/powershell:7.2-ubuntu-22.04 && \
sudo docker pull ubuntu:18.04 && \
sudo docker pull mcr.microsoft.com/mssql/server:2019-latest && \
sudo docker pull container-registry.oracle.com/database/express:latest && \
sudo docker pull mysql:latest && \
sudo docker pull mariadb:latest && \
sudo docker pull postgres:latest && \
sudo docker pull ibmcom/db2:latest && \
sudo docker pull ibmcom/informix-developer-database:latest && \
echo 'OK'
