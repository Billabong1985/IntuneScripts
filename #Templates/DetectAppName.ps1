#Define the app display name, use wildcards to catch any minor changes to name between versions
$AppName = "*App*Name*"

#Get app details from registry, add additional Where-Object qualifiers if more than one entry matches the display name
$AppReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
$AppNameReg = $AppReg | Get-ItemProperty | Where-Object {$_.DisplayName -like $AppName}

#Check if the app has a registry entry, write output if it does
if($null -ne $AppNameReg)
    {
    write-host Installed
    }
