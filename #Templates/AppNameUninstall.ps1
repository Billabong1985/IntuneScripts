#Define the app properties to filter from registry use partial wildcards to catch any minor variations on display names
#Unused properties should be set to "" or $null to exclude them from the filter string, or delete the pscustomobject line
#In most cases the DisplayName -like property will be sufficient, additional properties can be used for apps that can't be singled out with that alone
$RegFilters = @(
    [pscustomobject]@{ Property = "DisplayName"; Operator = "Like"; String = "*App*Name*" }
    [pscustomobject]@{ Property = "DisplayName"; Operator = "NotLike"; String = "" }
    [pscustomobject]@{ Property = "Publisher"; Operator = "Like"; String = "*Publisher*" }
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
