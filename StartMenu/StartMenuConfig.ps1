<#
Configures Windows start menu layouts by editing registry

Uses a custom function to import a registry key array from
a csv file, then create/set the key values as necessary
#>

#Set variables
$WinVer = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
$CurrentUser = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName).Split('\')[-1]
$LogFolder = "C:\Software\StartMenu"
$LogFile = "$LogFolder\StartMenuConfig$CurrentUser.log"

#Clear content from the log folder if it already exists
Clear-Content $LogFile -ErrorAction Ignore

#Define the CSV file to pass to the function if Windows version is 10
if ($WinVer -like '*Windows 10*') {
    $CsvFile = "$PSScriptRoot\win10regkeys.csv"
}
#Define the CSV file to pass to the function if Windows version is 11
if ($WinVer -like '*Windows 11*') {
    $CsvFile = "$PSScriptRoot\win11regkeys.csv"
}

#Import the registry editing function and pass the defined csv and log files to it
If (!(Get-Module -Name Set-Regkeys)) {
    Import-Module "$PSScriptRoot\Set-Regkeys.psm1"
}
Set-RegKeys -CsvImport $CsvFile -LogResults $LogFile
