#Define the app display name, use wildcards to catch any minor changes to name between versions
$AppName = "*Adobe*Acrobat*"
#Define the package version number
[version]$PackageVersion = "24.2.21005"

#Get app details from registry, add additional Where-Object qualifiers if more than one entry matches the display name
$AppReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
$AppNameReg = $AppReg | Get-ItemProperty | Where-Object {($_.DisplayName -like $AppName) -and ($_.DisplayName -notlike "*Language*")}

#Define the currently installed version number
[version]$CurrentVersion = ($AppNameReg).DisplayVersion

#Check whether the installed version is greater than or equal to the package and set variable
if($currentversion -ge $packageversion)
    {
    $installed = "True"
    }
else
    {
    $installed = "False"
    }

#Check whether desktop shortcut has been deleted and set variable
if(!(test-path "C:\Users\Public\Desktop\Adobe Acrobat.lnk"))
    {
    $shortcutdeleted = "True"
    }
else
    {
    $shortcutdeleted = "False"
    }

#Check whether all customisation registry keys are present and set correctly
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

#Count how many reg keys are in the array
$keycount = $regkeys.Count
#Set the success count to an initial value of 0
$successcount = 0
#For each key value in the array, compare to the system registry and add 1 to the count if it matches
foreach($reg in $regkeys)
    {
        if(((get-itemproperty -path $reg.key -name $reg.name -ErrorAction SilentlyContinue).($reg.name)) -eq $reg.value)
        {
        $successcount ++
        }
    }

#If the success count matches the count of keys in the array, set variable as true
if($successcount -eq $keycount)
    {
    $custom = "True"
    }
else
    {
    $custom = "False"
    }

#If no conditions are False, output a success result
if("False" -notin @($installed,$shortcutdeleted,$custom))
    {
    Write-Host "Success"
    }
