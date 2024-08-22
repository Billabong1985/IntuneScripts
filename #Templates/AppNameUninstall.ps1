#Define the App's display name, use wildcards to catch any minor changes to name between versions
$AppName = "*App*Name*"

#Get the uninstall string(s) for the app, add additional Where-Object qualifiers if more than one app matches the display name
$AppReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
$AppNameReg = $AppReg | Get-ItemProperty  | Where-Object {$_.DisplayName -like $AppName}

#Set the variable to the quiet uninstall string if it exists, otherwise use standard uninstall string
if($null -ne ($AppNameReg).QuietUninstallString)
    {
    $Uninstall = ($AppNameReg).QuietUninstallString
    }
else
    {
    $Uninstall = ($AppNameReg).UninstallString
    }

#Split the string to define arguments then execute
$MSI = "MsiExec.exe"
if($Uninstall -match $MSI)
    {
    $Split = ($Uninstall -split '{') | Where-Object { $_.Trim() -ne "" }
    $Arguments = "{"+$Split[1]
    Start-Process $MSI -Wait -ArgumentList "/x $Arguments /qn"
    }
else 
    {
    $Split = ($Uninstall -split '"').Trim() | Where-Object { $_.Trim() -ne "" }
    Start-Process $Split[0] -Wait -ArgumentList $Split[1]
    }
