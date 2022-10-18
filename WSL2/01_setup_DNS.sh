#!/bin/bash

echo "[network]" >> /etc/wsl.conf && \
echo "generateResolvConf = false" >> /etc/wsl.conf && \
rm /etc/resolv.conf && \
echo "nameserver 1.1.1.1" > /etc/resolv.conf && \
echo 'OK'
