###################################################################
#                                                                 #
# Configures Windows start menu layouts by editing registry       #
#                                                                 #
# Uses a custom function to import a registry key array from      #
# a csv file, then create/set the key values as necessary         #
#                                                                 #
###################################################################

#Set variables
$winver = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
$logfolder = "C:\Software\StartMenu"
$logfile = "$logfolder\StartMenuConfig.log"

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

#Define the CSV file to pass to the function if Windows version is 10
if ($winver -like '*Windows 10*')
    {
    $csvfile = "$PSScriptRoot\win10regkeys.csv"
    }
#Define the CSV file to pass to the function if Windows version is 11
if ($winver -like '*Windows 11*')
    {
    $csvfile = "$PSScriptRoot\win11regkeys.csv"
    }

#Import the registry editing function and pass the defined csv and log files to it
If(!(Get-Module -Name Set-Regkeys))
    {
    Import-Module "$PSScriptRoot\Set-Regkeys.psm1"
    }
Set-Regkeys -CsvImport $csvfile -LogResults $logfile
