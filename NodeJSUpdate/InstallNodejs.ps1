#Define the path the MSI files are stored in under the scriptroot. This can be root level but a subfolder containing only install files is preferable
$FilePath = "$PSScriptRoot\MSI"

#Set minimum safe version(s)
$SafeVersions = @("18.18.2", "20.8.1")
$SafeVersions = $SafeVersions.ForEach{ [version]$_ }

#Define the app properties to filter from registry. Use partial wildcards to catch any minor variations on display names
$RegFilters = @(
    [pscustomobject]@{ Property = "DisplayName"; Operator = "Like"; String = "*node.js*" }
    [pscustomobject]@{ Property = "DisplayName"; Operator = "NotLike"; String = "" }
    [pscustomobject]@{ Property = "Publisher"; Operator = "Like"; String = "" }
    [pscustomobject]@{ Property = "InstallLocation"; Operator = "Eq"; String = "" }
)

#Pull verion numbers from MSI files, create PSCustomObjects array to hold corresponding filename, display version and [version]
$FileNames = @((Get-ChildItem -Path $FilePath -Filter *.* -Recurse | Where-Object { ($_.Extension -eq ".msi") }).Name)
$DisplayVersions = @()
$PackageObjects = @()
foreach ($File in $FileNames) {
    $FileVersion = (Get-MSIProperty productversion -Path $FilePath\$File).value
    $DisplayVersions += $FileVersion
    $PackageObjects += [PSCustomObject]@{ FilePath = "$FilePath\$File"; DisplayVersion = $FileVersion; PackageVersion = [version]$FileVersion }  
}

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

#Compare each result's version number with the package version held in the Package array
foreach ($App in $AppNameReg) {
    #Define the currently installed version number
    [version]$CurrentVersion = $App.DisplayVersion
    #Find an object in the Package array with a matching Major version number
    $MatchingPackage = $PackageObjects | Where-Object { $_.PackageVersion.Major -eq $CurrentVersion.Major }
    $MatchingSafeVersion = $SafeVersions | Where-Object { $_.Major -eq $CurrentVersion.Major }

    #If the current version is less than the corresponding safe version, install the package
    if ($CurrentVersion -lt $MatchingSafeVersion) {
        $MSI = $MatchingPackage.FilePath
        start-process msiexec.exe -Wait -ArgumentList "/i $MSI /qn"
    }
}
