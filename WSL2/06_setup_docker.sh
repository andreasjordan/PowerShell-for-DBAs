#!/bin/bash

# Pull my favorite docker images

docker pull mcr.microsoft.com/powershell:7.3-ubuntu-22.04 && \
docker pull mcr.microsoft.com/mssql/server:2019-latest && \
docker pull container-registry.oracle.com/database/express:latest && \
docker pull mysql:latest && \
docker pull mariadb:10.9 && \
docker pull postgres:latest && \
docker pull postgis/postgis && \
echo 'OK'
