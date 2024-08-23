#Define the package version number
[version]$PackageVersion = "1.0.0"

#Define the app properties to filter from registry use partial wildcards to catch any minor variations on display names
#Unused properties should be set to '' or $null to exclude them from the filter string, or delete the pscustomobject line
#In most cases the DisplayName -like property will be sufficient, additional properties can be used for apps that can't be singled out with that alone
$RegFilters = @(
    [pscustomobject]@{ Property = "DisplayName"; Operator = "Like"; String = "*App*Name*" }
    [pscustomobject]@{ Property = "DisplayName"; Operator = "NotLike"; String = "" }
    [pscustomobject]@{ Property = "Publisher"; Operator = "Like"; String = "*Publisher*" }
    [pscustomobject]@{ Property = "InstallLocation"; Operator = "Like"; String = "" }
)

#Create a filter format template
$FilterTemplate = '$_.{0} -{1} "{2}"'
#Build a combined filter string using the format template, based on the $RegFilters variables with a String value
#-Replace '(.+)', '($0)' encapsulates each individual filter in parentheses, which is not strictly necessary, but can help readability
$AllFilters = $RegFilters.Where({ $_.String }).foreach({ $FilterTemplate -f $_.Property, $_.Operator, $_.String }) -Replace '(.+)', '($0)' -Join ' -and '
#Convert the string to a scriptblock
$AllFiltersScript = [scriptblock]::Create($AllFilters)

#Get app details from registry
$AppReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
$AppNameReg = @($AppReg | Get-ItemProperty | Where-Object -FilterScript $AllFiltersScript)

#If 1 app is returned, compare it's version number with the package version
if ($AppNameReg.count -eq 1) {
    #Define the currently installed version number
    [version]$CurrentVersion = $AppNameReg.DisplayVersion
    #Check if the currently installed version is greater than or equal to the package version, write output if it is and exit 0
    if ($CurrentVersion -ge $PackageVersion) {
        write-host Installed
        Exit 0
    }  
}

#If more than 1 app is returned from registry, write a log file with the details for review and exit 1
if ($AppNameReg.count -gt 1) {
    $LogFolder = "C:\Software\AppVersionDetection"
    if (!(Test-Path $LogFolder)) {
        New-Item -ItemType Directory -Force -Path $logfolder
    }
    $FileName = (($RegFilters).String[0]) -Replace '["*]', ''
    $LogFile = "$LogFolder\$FileName.log"
    $DateTime = (Get-Date)
    Clear-Content $LogFile -ErrorAction Ignore
    Add-Content $LogFile $DateTime
    Add-Content $LogFile "More than 1 app filtered based on supplied criteria, version number cannot be confirmed"
    Add-Content $LogFile "See list of returned registry keys below and refine filters to single out correct app"
    $AppNameReg | ForEach-Object { $_ | Out-String } | Add-Content -Path $LogFile
    Exit 1
}
