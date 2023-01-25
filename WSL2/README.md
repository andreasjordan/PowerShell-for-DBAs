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

You need to execute the shell scripts starting with 01 to 05 with sudo.

Script `08_import_docker_images.ps1` uses "C:\tmp\DockerImages" to save the images for a later run. Please make sure to have that directory in place or change the script to use a different directory.

If you want to run all scripts at once, use:
```
sudo ./01_setup_DNS.sh && \
sudo ./02_update_packages.sh && \
sudo ./03_install_pwsh.sh && \
sudo ./04_install_docker.sh && \
sudo ./05_install_7zip.sh && \
pwsh ./06_install_pwsh_modules.ps1 && \
pwsh ./07_select_databases.ps1 && \
pwsh ./08_import_docker_images.ps1 && \
pwsh ./09_start_databases.ps1 && \
pwsh ../PowerShell/01_SetupSampleDatabases.ps1 && \
pwsh ../PowerShell/02_SetupSampleSchemas.ps1 && \
pwsh ../PowerShell/03_ImportSampleDataFromJson.ps1 && \
pwsh ../PowerShell/04_ImportSampleDataFromStackexchange.ps1 && \
pwsh ../PowerShell/05_ImportSampleGeographicData.ps1 && \
echo 'All OK'
```


## Use the new WSL2

I included some PowerShell scripts to work with the containers:
* start_container.ps1
* stop_container.ps1

I plan to include more scripts later...
