Copy function file to root of script

Customise the template CSV file regkeys.csv and place in the same root directory

Multiple CSV files with unique names can be used if different values are needed depending on variables

The CSV file name to be used should be defined in the script and passed to the function using the -CsvImport parameter

Optionally a log file can be passed using the -LogResults parameter


################## Example 1 ###################

If(!(Get-Module -Name Set-Regkeys))
    {
    Import-Module "$PSScriptRoot\Set-Regkeys.psm1"
    }
$logfile = C:\Software\Application\LogFile.log
$csvfile = "$PSScriptRoot\regkeys.csv"
Set-Regkeys -CsvImport $csvfile -LogResults $logfile

################################################

################## Example 2 ###################

If(!(Get-Module -Name Set-Regkeys))
    {
    Import-Module "$PSScriptRoot\Set-Regkeys.psm1"
    }
If($variable = 1)
   {
   $csvfile = "$PSScriptRoot\regkeys1.csv"
   }
If($variable = 2)
   {
   $csvfile = "$PSScriptRoot\regkeys2.csv"
   }
Set-Regkeys -CsvImport $csvfile

################################################
