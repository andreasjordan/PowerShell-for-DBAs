#!/bin/bash

# This script can be run again later to refresh the repository.
[ -d ~/GitHub/PowerShell-for-DBAs ] && rm -rf ~/GitHub/PowerShell-for-DBAs

# On first run, create the folder.
[ ! -d ~/GitHub ] && mkdir ~/GitHub

# Clone the repository.
cd ~/GitHub && \
git clone https://github.com/andreasjordan/PowerShell-for-DBAs.git && \
echo 'OK'
