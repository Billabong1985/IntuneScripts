#Variables here to be passed through to the script below the function

#Define the registry search strings, hash out any that are not needed
$AppNameSearchString = '"*App*Name*"'
#$AppNameSearchExcludeString = '@("*Exclude*","*Exclude2*")'
$PublisherSearchString = '"*Publisher*"'

#Define the command to pass to the function, remove any unused parts
#$GetAppRegCommand = "(Get-AppReg -AppNameLike $AppNameSearchString -AppNameNotLike $AppNameSearchExcludeString -PublisherLike $PublisherSearchString)"
$GetAppRegCommand = "(Get-AppReg -AppNameLike $AppNameSearchString -PublisherLike $PublisherSearchString)"
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

#Define the app registry entry by calling the function. -AppNameNotLike is set up as an array and can accept multiple strings
$AppNameReg = @(Invoke-Expression $GetAppRegCommand)

#If 1 app is returned, write output and exit 0
if ($AppNameReg.count -eq 1) {
    write-host Installed
    Exit 0
}

#If more than 1 app is returned from registry, write a log file with the details for review and exit 1
if ($AppNameReg.count -gt 1) {
    $LogFolder = "C:\Software\AppDetection"
    if (!(Test-Path $LogFolder)) {
        New-Item -ItemType Directory -Force -Path $logfolder
    }
    $FileName = (($AppNameReg).DisplayName[0]) -Replace " ", ""
    $LogFile = "$LogFolder\$FileName.log"
    $DateTime = (Get-Date)
    Clear-Content $LogFile -ErrorAction Ignore
    Add-Content $LogFile $DateTime
    Add-Content $LogFile "More than 1 app filtered based on supplied criteria, correct app cannot be confirmed"
    Add-Content $LogFile "See list of returned registry keys below and refine filters to single out correct app"
    $AppNameReg | ForEach-Object { $_ | Out-String } | Add-Content -Path $LogFile
    Exit 1
}
