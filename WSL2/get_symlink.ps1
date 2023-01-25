"sudo ln -s '/mnt/$($PWD.Drive.Name.ToLower())$($PWD.Path.Replace('\', '/').Substring(2).Replace('/WSL2', ''))' /mnt/PowerShell-for-DBAs && cd /mnt/PowerShell-for-DBAs/WSL2" | Set-Clipboard
