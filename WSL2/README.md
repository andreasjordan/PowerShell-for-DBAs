# Setup WSL2 for working with pwsh, docker and a lot of databases


## Setup Ubuntu in WSL2

Will be added later...

## Reset the current WSL2

To remove the current WSL2, run this in an elevated cmd:
```
wsl --unregister Ubuntu-22.04
```

## Setup the new WSL2

Just open it via start menu and follow the instructions. Then wait until it can be rebooted.

Create a symbolic link to access the scripts in this folder from inside the WSL2 with a short path. Run get_symlink.ps1 in this folder to copy the needed command to the clibboard.

Then paste the command in the linux vm and execute it. You will be placed in this folder and can now easily execute the numbered scripts to setup the vm. 

You need to execute the shell scripts starting with 01, 02, 03, 05 and 06 with sudo.

If you want to run all scripts at once, use:
```
sudo ./01_setup_DNS.sh && \
sudo ./02_update_packages.sh && \
sudo ./03_install_pwsh.sh && \
./04_setup_pwsh.ps1 && \
sudo ./05_install_docker.sh && \
sudo ./06_setup_docker.sh && \
./07_setup_git.sh && \
./08_setup_container.sh && \
echo 'All OK'
```
