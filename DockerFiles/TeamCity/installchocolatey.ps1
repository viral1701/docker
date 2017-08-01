######################################################################Install Chocolatey#####################################################################################################################################

iex ((New-Object System.Net.WebClient).DownloadString("https://chocolatey.org/install.ps1"))

#######################################################################Install Java Chocolatey###############################################################################################################################
choco upgrade jdk8 -y

########################################################################Install TeamCity BuildAgent###########################################################################################################################
Write-Output "Begin installing Teamcity Agent Service."

$serverUrl = "http://192.168.133.131"
$agentDir = "$env:SystemDrive\buildAgent"
$agentName = "$env:COMPUTERNAME"
$agentDrive = Split-Path $agentDir -Qualifier
$DownloadURI = "$serverUrl" + "/update/buildAgent.zip"

## Temporary folder
$tempFolder = $env:TEMP
$package_path = "$tempFolder\buildagent.zip"

## Download from TeamCity server
Write-Output "Get BuildAgent.zip from $DownloadURI'"
$webclient = New-Object System.Net.WebClient
$webclient.DownloadFile($DownloadURI,$package_path)
#Get-ChocolateyWebFile 'buildAgent.zip' "$tempFolder\buildAgent.zip" "$DownloadURI"

 
## Extract
Write-Output "Extract the zip file"
New-Item -ItemType Directory -Force -Path $agentDir
Expand-Archive -Path $package_path -DestinationPath $agentDir
#Get-ChocolateyUnzip "$tempFolder\buildAgent.zip" $agentDir 
 
## Clean up
#del /Q "$tempFolder\buildAgent.zip"
 
# Configure agent
Write-Output "Configure the agent"
copy $agentDir\conf\buildAgent.dist.properties $agentDir\conf\buildAgent.properties
(Get-Content $agentDir\conf\buildAgent.properties) | Foreach-Object {
    $_ -replace 'serverUrl=http://localhost:8111/', "serverUrl=$serverUrl" -replace 'name=', "name=$agentName"
    } | Set-Content $agentDir\conf\buildAgent.properties
 
Set-Location "C:\buildagent\bin"

#Start-Process -FilePath .\service.install.bat -Wait

cmd.exe /c .\service.install.bat

###############################################################################################################################################################################################################################



####Install TeamCity Agent Service

Get-Service -Name TCBuildAgent | Start-Service -Verbose

#################################################################################################################################################################################

function Add-ContainerHostEntry
{
  [CmdletBinding()]

  param(
         [Parameter(Mandatory=$true)]
         [ipaddress]$IP,
         [Parameter(Mandatory=$true)]
         [string] $hostName

         )

$hostsPath = "$env:windir\System32\drivers\etc\hosts"

$hosts = Get-Content $hostsPath

$match = $hosts -match ("^\s*$ip\s+$hostName" -replace '\.', '\.')

If ($match) { "Do Nothing" }

$hostsEntry = "$ip`t$hostName"

If ([IO.File]::ReadAllText($hostsPath) -notmatch "\r\n\z") { $hostsEntry = [environment]::newline + $hostsEntry }

[System.IO.File]::AppendAllText($hostsPath,$hostsEntry)

}

Add-ContainerHostEntry -IP "192.168.133.129" -hostName "octopus.home.net"
Add-ContainerHostEntry -IP "192.168.133.131" -hostName "teamcity.home.net"