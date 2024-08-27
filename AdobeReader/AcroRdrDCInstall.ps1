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
$AppNameReg = @(Get-AppReg -AppNameLike "*Acrobat*" -PublisherLike "*Adobe*" -AppNameNotLike @("*Refresh*Manager*","*Customization*Wizard*"))

#Define the package file
$Package = "$PSScriptRoot\AcroRdrDC_MUI.exe"

#Define log folder and file, clear content if it already exists
$LogFolder = "C:\Software\AcrobatReader"
if (!(Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Force -Path $LogFolder
}
$LogFile = "$LogFolder\AcroRdrInstallConfig.log"
Clear-Content $LogFile -ErrorAction Ignore

#If 0 or 1 app is returned, compare version number with the package version
if ($AppNameReg.count -le 1) {
    #Define the currently installed version number
    [version]$CurrentVersion = ($AppNameReg).DisplayVersion
    #Install Acrobat Reader if it is not already installed or current version is lower than package version
    if (($null -eq $CurrentVersion) -or ($CurrentVersion -lt $PackageVersion)) {
        start-process $Package -wait -ArgumentList "/sAll /rs /msi EULA_ACCEPT=YES"
    }  
}

#If more than 1 app is returned from registry, write a log file with the details for review and break
if ($AppNameReg.count -gt 1) {
    $DateTime = (Get-Date)
    Clear-Content $LogFile -ErrorAction Ignore
    Add-Content $LogFile $DateTime
    Add-Content $LogFile "More than 1 app filtered based on supplied criteria, version number cannot be confirmed"
    Add-Content $LogFile "See list of returned registry keys below and refine filters to single out correct app"
    $AppNameReg | ForEach-Object { $_ | Out-String } | Add-Content -Path $LogFile
    Break
}

#Delete desktop shortcut if found
if (Test-Path "C:\Users\Public\Desktop\Adobe Acrobat.lnk") {
    Remove-Item "C:\Users\Public\Desktop\Adobe Acrobat.lnk"
}

#Import the registry editing function if it is not already loaded
If (!(Get-Module -Name Set-Regkeys)) {
    Import-Module "$PSScriptRoot\Set-Regkeys.psm1"
}
#Define the CSV file to import registry settings from
$CsvFile = "$PSScriptRoot\regkeys.csv"
#Run the function, passing the defined CSV file
Set-RegKeys -CsvImport $CsvFile -LogResults $LogFile
