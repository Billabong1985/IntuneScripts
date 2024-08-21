#Define the app display name, use wildcards to catch any minor changes to name between versions
$AppName = "*App*Name*"
#Define the package version number
[version]$PackageVersion = "1.0.0"

#Get app details from registry, add additional Where-Object qualifiers if more than one entry matches the display name
$AppReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
$AppNameReg = $AppReg | Get-ItemProperty | Where-Object {$_.DisplayName -like $AppName }

#Define the currently installed version number
[version]$CurrentVersion = ($AppNameReg).DisplayVersion

#Check if the currently installed version is greater than or equal to the package version, write output if it is
if($CurrentVersion -ge $PackageVersion)
    {
    write-host Installed
    }
