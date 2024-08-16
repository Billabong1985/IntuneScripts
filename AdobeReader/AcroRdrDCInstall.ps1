#Define the package file
$package = "$PSScriptRoot\AcroRdrDC_MUI.exe"

#Get the version number of Adobe if it is already installed
[version]$currentversion = ((Get-Package | Where-Object {$_.Name -like "*Adobe*Acrobat*" -and $_.Name -notlike "*Language*"}).version)
#Get the version number of the package file as a string, remove any trailing .0 and convert to [version] format
[string]$packageversion = (get-item -path $package | ForEach-Object {$_.VersionInfo} | Select-Object FileVersion).FileVersion
if($packageversion.EndsWith(".0")) 
    {
    $packageversion = $packageversion.TrimEnd(".0")
    }
[version]$packageversion = "$packageversion"

#Define log folder and file
$logfolder = "C:\Software\AcrobatReader"
$logfile = "$logfolder\AcroRdrInstallConfig.log"

#Check if log file exists, clear content if it does
If(test-path $logfile)
    {
    Clear-Content $logfile
    }
#Check if log folder exists, create it if not
If(!(test-path $logfolder))
    {
    New-Item -ItemType Directory -Force -Path $logfolder
    }   
#Check if log file exists, create it if not
If(!(test-path $logfile))
    {
    New-Item $logfile
    }

Start-Transcript -Path $logfile

#Install Acrobat Reader if it is not already installed or current version is lower than package version
if(($null -eq $currentversion) -or ($currentversion -lt $packageversion))
    {
    start-process $package -wait -ArgumentList "/sAll /rs /msi EULA_ACCEPT=YES"
    }

#Delete desktop shortcut if found
if(Test-Path "C:\Users\Public\Desktop\Adobe Acrobat.lnk")
    {
    Remove-Item "C:\Users\Public\Desktop\Adobe Acrobat.lnk"
    }

#Import the registry editing function if it is not already loaded
If(!(Get-Module -Name Set-Regkeys))
    {
    Import-Module "$PSScriptRoot\Set-Regkeys.psm1"
    }
#Define the CSV file to import registry settings from
$csvfile = "$PSScriptRoot\regkeys.csv"
#Run the function, passing the defined CSV file
Set-Regkeys -CsvImport $csvfile

Stop-Transcript
