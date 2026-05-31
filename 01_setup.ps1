$ErrorActionPreference = 'Stop'

# Setup WSL2
wsl --cd $PSScriptRoot --user root ./02_wsl2_setup.sh
if ($LASTEXITCODE -ne 0) { throw 'failure in 02_wsl2_setup.sh'}

# Setup PowerShell
wsl --cd $PSScriptRoot --user root pwsh ./03_pwsh_setup.ps1
if ($LASTEXITCODE -ne 0) { throw 'failure in 03_pwsh_setup.ps1'}

# Shutdown needed by docker
wsl --shutdown

# Select databases to run
wsl --cd $PSScriptRoot --user root pwsh ./04_select_databases.ps1
if ($LASTEXITCODE -ne 0) { throw 'failure in 04_select_databases.ps1'}

# Create database containers
wsl --cd $PSScriptRoot --user root pwsh ./05_create_containers.ps1
if ($LASTEXITCODE -ne 0) { throw 'failure in 05_create_containers.ps1'}

# Setup sample databases
wsl --cd $PSScriptRoot --user root pwsh ./PowerShell/01_SetupSampleDatabases.ps1
if ($LASTEXITCODE -ne 0) { throw 'failure in 01_SetupSampleDatabases.ps1'}

# Setup sample schemas
wsl --cd $PSScriptRoot --user root pwsh ./PowerShell/02_SetupSampleSchemas.ps1
if ($LASTEXITCODE -ne 0) { throw 'failure in 02_SetupSampleSchemas.ps1'}

# Import sample data from JSON
wsl --cd $PSScriptRoot --user root pwsh ./PowerShell/03_ImportSampleDataFromJson.ps1
if ($LASTEXITCODE -ne 0) { throw 'failure in 03_ImportSampleDataFromJson.ps1'}

# Import sample data from Stack Exchange
wsl --cd $PSScriptRoot --user root pwsh ./PowerShell/04_ImportSampleDataFromStackexchange.ps1
if ($LASTEXITCODE -ne 0) { throw 'failure in 04_ImportSampleDataFromStackexchange.ps1'}

# Import sample geographic data
wsl --cd $PSScriptRoot --user root pwsh ./PowerShell/05_ImportSampleGeographicData.ps1
if ($LASTEXITCODE -ne 0) { throw 'failure in 05_ImportSampleGeographicData.ps1'}

# Run WSL2 to keep docker containers running
wsl --cd $PSScriptRoot --user root
