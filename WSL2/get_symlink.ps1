"sudo ln -s '/mnt/$($PWD.Drive.Name.ToLower())$($PWD.Path.Replace('\', '/').Substring(2))' /mnt/setup && cd /mnt/setup" | Set-Clipboard
