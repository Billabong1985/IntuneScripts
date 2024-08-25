#Define the package version numbers
$PackageVersions = @("18.20.2", "20.12.2")
$PackageVersions = $PackageVersions.ForEach{ [version]$_ }
#Define the app properties to filter from registry use partial wildcards to catch any minor variations on display names
#Unused properties should be set to "" or $null to exclude them from the filter string, or delete the pscustomobject line
#In most cases the DisplayName -like property will be sufficient, additional properties can be used for apps that can't be singled out with that alone
$RegFilters = @(
    [pscustomobject]@{ Property = "DisplayName"; Operator = "Like"; String = "*Node*JS*" }
    [pscustomobject]@{ Property = "DisplayName"; Operator = "NotLike"; String = "" }
    [pscustomobject]@{ Property = "Publisher"; Operator = "Like"; String = "" }
    [pscustomobject]@{ Property = "InstallLocation"; Operator = "Eq"; String = "" }
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

#If no more apps are returned than the number of specified versions, compare version numbers with the corresponding package versions
if (($AppNameReg.count -gt 0) -and ($AppNameReg.count -le $PackageVersions.count)) {
    #Create an array to record up to date versions
    $InstallComplete = @()
    foreach ($App in $AppNameReg) {
        #Define the currently installed version number
        [version]$CurrentVersion = $App.DisplayVersion
        $CurrentVersionMajor = $CurrentVersion.Major
        #Find the version in the $PackageVersions array that has matching Major version
        $MatchingAppVersion = $PackageVersions | Where-Object { $_.Major -eq $CurrentVersionMajor }
        if (($null -ne $MatchingAppVersion) -and ($CurrentVersion -ge $MatchingAppVersion)) {
            $InstallComplete += [PSCustomObject]@{ Version = $MatchingAppVersion; Installed = "True" }
            }
        if (($null -ne $MatchingAppVersion) -and ($CurrentVersion -lt $MatchingAppVersion)) {
            $InstallComplete += [PSCustomObject]@{ Version = $MatchingAppVersion; Installed = "False" }
            }
        }
    }

#If at least 1  install has been detected and the version number is greater than or equal to the specified package version(s), write to host and exit 0
If(($null -ne $InstallComplete)-and ("False" -notin $InstallComplete.Installed)) {
    Write-Host Installed
    Exit 0
}
    
#If more than apps are returned from registry than specified versions, write a log file with the details for review and exit 1
if ($AppNameReg.count -gt $PackageVersions.count) {
    $LogFolder = "C:\Software\AppVersionDetection"
    if (!(Test-Path $LogFolder)) {
        New-Item -ItemType Directory -Force -Path $logfolder
    }
    $FileName = (($RegFilters).String[0]) -Replace "[*]", ""
    $LogFile = "$LogFolder\$FileName.log"
    $DateTime = (Get-Date)
    Clear-Content $LogFile -ErrorAction Ignore
    Add-Content $LogFile $DateTime
    Add-Content $LogFile "Too many apps filtered based on supplied criteria, version number(s) cannot be confirmed"
    Add-Content $LogFile "See list of returned registry keys below and refine filters to single out correct app(s)"
    $AppNameReg | ForEach-Object { $_ | Out-String } | Add-Content -Path $LogFile
    Exit 1
}
