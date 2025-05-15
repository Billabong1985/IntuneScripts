#Variables here to be passed through to the script below the function
#Define log folder
$LogFolder = "C:\Software\AcrobatReader"
if (!(Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Force -Path $LogFolder
}
$LogFile = "$LogFolder\AcroRdrUninstall.log"

#Define the registry search strings, hash out any that are not needed
$AppNameSearchString = '"*Acrobat*"'
$AppNameSearchExcludeString = '@("*Refresh*Manager*", "*Customization*Wizard*")'
$PublisherSearchString = '"*Adobe*"'

#Define the command to pass to the function, remove any unused parts
$GetAppRegCommand = "(Get-AppReg -AppNameLike $AppNameSearchString -AppNameNotLike $AppNameSearchExcludeString -PublisherLike $PublisherSearchString)"
#End of variables to be changed

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
    foreach ($String in $AppNameNotLike) {
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

#Start Logging
Start-Transcript -Path $LogFile

#Define the app registry entry by calling the function. -AppNameNotLike is set up as an array and can accept multiple strings
$AppNameReg = @(Invoke-Expression $GetAppRegCommand)

#If no matching apps are found, write host and exit
If (!($AppNameReg)) {
    Write-Host "$(Get-Date): No matching apps found, script will now exit"
    Exit 0
    #Otherwise continue with the uninstall script
}
Else {
    #Use a foreach loop to uninstall all versions of the app if more than one result is returned
    foreach ($App in $AppNameReg) { 
        Write-Host "$(Get-Date): Found $($App.DisplayName) version $($App.DisplayVersion)"

        #Set the variable to the quiet uninstall string if it exists, otherwise use standard uninstall string
        if ($null -ne $App.QuietUninstallString) {
            $Uninstall = $App.QuietUninstallString
        }
        else {
            $Uninstall = $App.UninstallString
        }

        #Split the string to define arguments then execute
        $MSI = "MsiExec.exe"
        if ($Uninstall -match $MSI) {
            $Identifier = $Uninstall  | Select-String -Pattern "\{[A-F0-9-]+\}" -AllMatches | ForEach-Object { $_.Matches.Value }
            Write-Host "$(Get-Date): Uninstalling $($App.DisplayName) version $($App.DisplayVersion)..."
            Start-Process $MSI -Wait -ArgumentList "/x $Identifier /qn"
        }
        else {
            $SplitString = ($Uninstall -split '"').Trim() | Where-Object { $_.Trim() -ne "" }
            Write-Host "$(Get-Date): Uninstalling $($App.DisplayName) version $($App.DisplayVersion)..."
            Start-Process $SplitString[0] -Wait -ArgumentList $SplitString[1]
        }
    }
    #Check registry again
    $AppNameReg = @(Invoke-Expression $GetAppRegCommand)

    #Write results
    if (!($AppNameReg)) {
        Write-Host "$(Get-Date): All detected apps have been successfully uninstalled"
    }
    else {
        ForEach ($App in $AppNameReg) {
            Write-Host "$(Get-Date): $($App.DisplayName) version $($App.DisplayVersion) still detected after uninstall attempt"
        }
    }
}

#Stop Logging
Stop-Transcript
