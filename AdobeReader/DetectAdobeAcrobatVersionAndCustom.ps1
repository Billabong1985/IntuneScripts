#Variables here to be passed through to the script below the function
#Define a log file, clear it if it already exists
$LogFolder = "C:\Software\AppVersionDetection"
if (!(Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Force -Path $logfolder
}
$LogFile = "$LogFolder\AdobeAcrobat.log"

#Define the registry search strings, hash out any that are not needed
$AppNameSearchString = '"*Acrobat*"'
$AppNameSearchExcludeString = '@("*Refresh*Manager*","*Customization*Wizard*")'
$PublisherSearchString = '"*Adobe*"'

#Define the command to pass to the function, remove any unused parts
$GetAppRegCommand = "(Get-AppReg -AppNameLike $AppNameSearchString -AppNameNotLike $AppNameSearchExcludeString -PublisherLike $PublisherSearchString)"

#Define the package version
[version]$PackageVersion = "24.4.20220"
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

#Define the app registry entry by calling the function
#Define the app registry entry by calling the function. -AppNameNotLike is set up as an array and can accept multiple strings
$AppNameReg = @(Invoke-Expression $GetAppRegCommand)

#If 1 app is returned, or none, compare version number with the package version
if ($AppNameReg.Count -le 1) {
    #Define the currently installed version number
    [version]$CurrentVersion = $AppNameReg.DisplayVersion
    #Check if the currently installed version is greater than or equal to the package version, write output if it is and exit success
    if ($CurrentVersion -ge $PackageVersion) {
        $Installed = $true
    }
    else {
        $Installed = $false
    }
}

#If more than 1 app is returned from registry, write to log file with the details for review
if ($AppNameReg.Count -gt 1) {
    $Installed = $false
    Add-Content $LogFile "$(Get-Date): More than 1 app filtered based on supplied criteria, version number cannot be confirmed"
    Add-Content $LogFile "$(Get-Date): returned registry keys below and refine filters to single out correct app"
    $AppNameReg | ForEach-Object { $_ | Out-String } | Add-Content -Path $LogFile
}

#Check whether desktop shortcut has been deleted and set variable
if (!(test-path "C:\Users\Public\Desktop\Adobe Acrobat.lnk")) {
    $ShortcutDeleted = $true
}
else {
    $ShortcutDeleted = $false
}

#Check whether all customisation registry keys are present and set correctly
#Create array of reg keys
$RegKeys = @(
    [pscustomobject]@{ Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"; Name = "bToggleFTE"; Type = "DWORD"; Value = "1" }
    [pscustomobject]@{ Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"; Name = "bAcroSuppressUpsell"; Type = "DWORD"; Value = "1" }
    [pscustomobject]@{ Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"; Name = "bToggleAdobeDocumentServices"; Type = "DWORD"; Value = "1" }
    [pscustomobject]@{ Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"; Name = "bToggleAdobeReview"; Type = "DWORD"; Value = "1" }
    [pscustomobject]@{ Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"; Name = "bTogglePrefsSync"; Type = "DWORD"; Value = "1" }
    [pscustomobject]@{ Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cSharePoint"; Name = "bDisableSharePointFeatures"; Type = "DWORD"; Value = "1" }
    [pscustomobject]@{ Key = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cWebmailProfiles"; Name = "bDisableWebmail"; Type = "DWORD"; Value = "1" }
)

#Count how many reg keys are in the array
$KeyCount = $RegKeys.Count
#Set the success count to an initial value of 0
$SuccessCount = 0
#For each key value in the array, compare to the system registry and add 1 to the count if it matches
foreach ($Reg in $RegKeys) {
    if (((Get-ItemProperty -path $Reg.Key -name $Reg.Name -ErrorAction SilentlyContinue).($Reg.Name)) -eq $Reg.Value) {
        $SuccessCount ++
    } else {
        Add-Content $LogFile "$(Get-Date): Registry key `"$($Reg.Key)\$($Reg.Name)`" not found or set to wrong value"
    }
}

#If the success count matches the count of keys in the array, set variable as true
if ($SuccessCount -eq $KeyCount) {
    $Custom = $true
}
else {
    $Custom = $false
}

#Store check results in a hash table
$Results = @{ Installed = $Installed; ShortcutDeleted = $ShortcutDeleted; Customisation = $Custom }

#If no checks are False, output a success result and exit 0
if ($false -notin $Results.Values) {
    Write-Host "Success"
    Exit 0
}

#If any checks are False, write them to log file and exit 1
else {
    $FalseResults = @()
    foreach ($Result in $Results.Keys) {
        if ($Results[$Result] -eq $false) {
            $FalseResults += $Result
        }
    }
    if ($FalseResults.count -ge 1) {
        Add-Content $LogFile "$(Get-Date): The following checks failed: $($FalseResults -join ', ')"
    }
    Exit 1
}
