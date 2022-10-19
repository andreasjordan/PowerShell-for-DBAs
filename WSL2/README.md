# Setup WSL2 for working with pwsh, docker and a lot of databases

Since I use a Windows 10 computer for my daily work, the easiest way to set up different database systems is to use Docker within the included WSL2. This solution does not use Docker Desktop and is therefore also free for professional use.

The WSL2 can be completely rebuilt very easily, providing a test environment that is always the same.


## Setup Ubuntu in WSL2

There are a lot of good resources out there, so I will just link some I used:
* https://learn.microsoft.com/en-us/windows/wsl/install-manual
* https://www.omgubuntu.co.uk/how-to-install-wsl2-on-windows-10
* https://michlstechblog.info/blog/windows-enable-windows-subsystem-for-linux/


## Reset the current WSL2

To remove the current WSL2, run this in an elevated cmd:
```
wsl --unregister Ubuntu-22.04
```


## Setup the new WSL2

Just open it via start menu and follow the instructions. Then wait until it can be rebooted.

Create a symbolic link to access the scripts in this folder from inside the WSL2 with a short path. Run get_symlink.ps1 in this folder to copy the needed command to the clipboard. Then paste the command in the linux vm and execute it. You will be placed in this folder and can now easily execute the numbered scripts to setup the vm. 

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

If you later want to update the resources, you just need to run the scripts starting with 07 and 08 again.


## Use the new WSL2

I included some PowerShell scripts to work with the containers:
* start_container.ps1
* stop_container.ps1
* rebuild_container.ps1

I plan include more scripts later...
