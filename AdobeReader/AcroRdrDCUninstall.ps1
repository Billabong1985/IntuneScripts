#Create the function
function Get-AppReg {
    #Define the Parameters
    param(
        [Parameter(Mandatory = $true)][string]$AppNameLike,
        [Parameter(Mandatory = $false)][string]$PublisherLike,
        [Parameter(Mandatory = $false)][string[]]$AppNameNotLike
    )

    #Create an array of objects for the registry search
    $RegFilters = @(
        [pscustomobject]@{ Property = "DisplayName"; Operator = "Like"; String = $AppNameLike }
        [pscustomobject]@{ Property = "Publisher"; Operator = "Like"; String = $PublisherLike }
    )
    foreach($String in $AppNameNotLike) {
        $RegFilters += [pscustomobject]@{ Property = "DisplayName"; Operator = "NotLike"; String = "$String" }
    }

    #Create a filter format template
    $FilterTemplate = '$_.{0} -{1} "{2}"'
    #Build a combined filter string using the format template, based on the $RegFilters variables with a String value
    #-Replace '(.+)', '($0)' encapsulates each individual filter in parentheses, which is not strictly necessary, but can help readability
    $AllFilters = $RegFilters.Where({ $_.String }).foreach({ $FilterTemplate -f $_.Property, $_.Operator, $_.String }) -Replace '(.+)', '($0)' -Join ' -and '
    #Convert the string to a scriptblock
    $AllFiltersScript = [scriptblock]::Create($AllFilters)

    #Get app details from registry and write output
    $AllAppsReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
    $AppReg = @($AllAppsReg | Get-ItemProperty | Where-Object -FilterScript $AllFiltersScript)
    Write-Output $AppReg
}

#Define the app registry entry by calling the function
$AppNameReg = Get-AppReg -AppNameLike "*Acrobat*" -PublisherLike "*Adobe*" -AppNameNotLike @("*Refresh*Manager*","*Customization*Wizard*")

#Use a foreach loop to uninstall all versions of the app if more than one result is returned
foreach($App in $AppNameReg)
    { 
    #Set the variable to the quiet uninstall string if it exists, otherwise use standard uninstall string
    if($null -ne $App.QuietUninstallString)
        {
        $Uninstall = $App.QuietUninstallString
        }
    else
        {
        $Uninstall = $App.UninstallString
        }

    #Split the string to define arguments then execute
    $MSI = "MsiExec.exe"
    if($Uninstall -match $MSI)
        {
        $Identifier = $Uninstall  | Select-String -Pattern "\{[A-F0-9-]+\}" -AllMatches | ForEach-Object { $_.Matches.Value }
        Start-Process $MSI -Wait -ArgumentList "/x $Identifier /qn"
        }
    else 
        {
        $SplitString = ($Uninstall -split '"').Trim() | Where-Object { $_.Trim() -ne "" }
        Start-Process $SplitString[0] -Wait -ArgumentList $SplitString[1]
        }
    }
