#Define the app properties to filter from registry, leave the string blank for any unused properties and use partial wildcards to catch any minor variations on others
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

#Use a foreach loop to uninstall all versions of the app if more than one result is returned
foreach($App in $AppNameReg)
    { 
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
    }
