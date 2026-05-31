$ErrorActionPreference = 'Stop'

if ((Get-PackageProvider).Name -notcontains 'NuGet') {
    $null = Install-PackageProvider -Name Nuget -Force
}
if ((Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue).InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}
$installedModules = (Get-Module -ListAvailable).Name 
foreach ($module in 'PSFramework Microsoft.PowerShell.ConsoleGuiTools'.Split(' ')) {
    if ($installedModules -notcontains $module) {
        # Only with "-Scope AllUsers", modules are installed to "/usr/local/share/powershell/Modules"
        # This is needed to mount the modules to the docker container
        # So this script needs to run with "sudo pwsh"
        Install-Module -Name $module -Scope AllUsers
    }
}
