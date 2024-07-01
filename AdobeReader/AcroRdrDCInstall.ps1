#Define the package file
$package = "$PSScriptRoot\AcroRdrDC_MUI.exe"

#Get the version number of Adobe if it is already installed
[version]$currentversion = ((Get-Package | Where-Object {$_.Name -like "*Adobe*Acrobat*" -and $_.Name -notlike "*Language*"}).version)
#Get the version number of the package file as a string, remove any trailing .0 and convert to [version] format
[string]$packageversion = (get-item -path $package | % {$_.VersionInfo} | select FileVersion).FileVersion
if($packageversion.EndsWith(".0")) 
    {
    $packageversion = $packageversion.TrimEnd(".0")
    }
[version]$packageversion = "$packageversion"

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

#Set customisations by editing registry
#Create array of reg keys
$regkeys = @(
[pscustomobject]@{
    Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"
    Name = "bToggleFTE"
    Type = "DWORD"
    Value = "1"
    }
[pscustomobject]@{
    Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"
    Name = "bAcroSuppressUpsell"
    Type = "DWORD"
    Value = "1"
    }
[pscustomobject]@{
    Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"
    Name = "bToggleAdobeDocumentServices"
    Type = "DWORD"
    Value = "1"
    }
[pscustomobject]@{
    Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"
    Name = "bToggleAdobeReview"
    Type = "DWORD"
    Value = "1"
    }
[pscustomobject]@{
    Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"
    Name = "bTogglePrefsSync"
    Type = "DWORD"
    Value = "1"
    }
[pscustomobject]@{
    Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cSharePoint"
    Name = "bDisableSharePointFeatures"
    Type = "DWORD"
    Value = "1"
    }
[pscustomobject]@{
    Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cWebmailProfiles"
    Name = "bDisableWebmail"
    Type = "DWORD"
    Value = "1"
    }
    )

#Execute commands on each entry in the array
foreach ($reg in $regkeys)
    {
    #If the reg key does not already exist, create it
    if(!(Get-Item -Path $reg.key -ErrorAction SilentlyContinue))
        {
        New-Item -Path $reg.key
        }
    #If the reg value does not already exist, create it
    if(!(Get-ItemProperty -Path $reg.key -Name $reg.name -ErrorAction SilentlyContinue))
        {
        New-ItemProperty -Path $reg.key -Name $reg.name -Value $reg.value  -PropertyType $reg.type
        }
    #If the existing reg value does not match the array, update it
    if(((Get-ItemProperty -Path $reg.key -Name $reg.name).($reg.name)) -ne $reg.value)
        {
        Set-ItemProperty -Path $reg.key -Name $reg.name -Value $reg.value
        }
    }