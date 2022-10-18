#!/bin/bash

# Pull my favorite docker images

docker pull mcr.microsoft.com/powershell:7.2-ubuntu-22.04 && \
docker pull ubuntu:18.04 && \
docker pull mcr.microsoft.com/mssql/server:2019-latest && \
docker pull container-registry.oracle.com/database/express:latest && \
docker pull mysql:latest && \
docker pull mariadb:latest && \
docker pull postgres:latest && \
docker pull ibmcom/db2:latest && \
docker pull ibmcom/informix-developer-database:latest && \
echo 'OK'
