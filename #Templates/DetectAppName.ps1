#Define the app properties to filter from registry, leave the string value blank for any unused properties or remove the respective pscustom object
#Partial wildcards can be used for string values to catch any minor variations between versions
#Note that the format for String values MUST be '"*String*"' to pass the "" characters through to the final filter string
#The format for Property and Operator values should be in the "Value" format
#In most cases the DisplayName -like property will be sufficient, additional properties can be used for apps that can't be singled out with that alone
$RegFilters = @(
    [pscustomobject]@{ Property = "DisplayName"; Operator = "-Like"; String = '"*App*Name*"' }
    [pscustomobject]@{ Property = "DisplayName"; Operator = "-NotLike"; String = '' }
    [pscustomobject]@{ Property = "Publisher"; Operator = "-Like"; String = '"*Publisher*"' }
    [pscustomobject]@{ Property = "InstallLocation"; Operator = "-Like"; String = '' }
)

#Build an array of conditions for all properties with a string value
$Filters = @()
foreach($Property in $RegFilters)
        {
            if(($Property).String)
            {
            $Filters += "(" + (('$_.' + ($Property).Property) + " " + (($Property).Operator) + " " + (($Property).String)) + ")"
            }
        }
#Combine the array into a single string
$AllFilters = $Filters -join " -and "

#Get app details from registry
$AppReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
$AppNameReg = $AppReg | Get-ItemProperty | Where-Object { Invoke-Expression $AllFilters}

#If 1 app is returned, write output and exit 0
if(($AppNameReg).count -eq 1)
    {
    write-host Installed
    Exit 0
    }

#If more than 1 app is returned from registry, write a log file with the details for review and exit 1
if(($AppNameReg).count -gt 1)
    {
    $LogFolder = "C:\Software\AppDetection"
    $FileName = (($RegFilters).String[0]) -Replace '["*]',''
    $LogFile = "$LogFolder\$FileName.log"
    $DateTime = (Get-Date)
    Clear-Content $LogFile -ErrorAction Ignore
    Add-Content $LogFile $DateTime
    Add-Content $LogFile "More than 1 app filtered based on supplied criteria, correct app cannot be confirmed"
    Add-Content $LogFile "See list of returned registry keys below and refine filters to single out correct app"
    $AppNameReg | ForEach-Object { $_ | Out-String } | Add-Content -Path $LogFile
    Exit 1
    }
