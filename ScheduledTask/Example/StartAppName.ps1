<#
StartAppName Script V1.1
#>

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

#Define the installed path
$AppInstallPath = (Get-AppReg -AppNameLike "*AppName*").InstallLocation
#Define the program executable path
$ExecutionPath = "$AppInstallPath\AppName.exe"

#Define the log file
$LogFolder = "C:\Software\AppName"
$LogFile = "$LogFolder\StartAppName.log"

#Check for log folder, create if it does not already exist
if (!(Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Force -Path $LogFolder
}

# Define the cutoff date (one month ago)
$LogTrimDate = (Get-Date).AddMonths(-1)
# Read the log file
$LogFileContent = Get-Content $LogFile -ErrorAction SilentlyContinue
# Filter lines based on the date at the start of each line
$FilteredContent = foreach ($line in $LogFileContent) {
    if ($line -match "^\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}") {
        $dateString = $matches[0]
        $entryDate = [datetime]::ParseExact($dateString, "MM/dd/yyyy HH:mm:ss", $null)
        if ($entryDate -ge $LogTrimDate) {
            $line
        }
    }
}
# Write the filtered content back to the log file
$FilteredContent | Set-Content $LogFile

#Check whether AppName is running, start it if not and write to log file
If ($null -eq (Get-Process -Name "AppName" -ErrorAction SilentlyContinue)) {
    $DateTime = (Get-Date)
    Add-Content $LogFile "$DateTime - AppName not running, attempting to start"
    Start-Process $ExecutionPath
    $AttemptCount = 0
    While (($null -eq (Get-Process -Name "AppName" -ErrorAction SilentlyContinue)) -and $AttemptCount -lt 6) {
        Start-Sleep 5
        $AttemptCount ++
    }
    If ($null -ne (Get-Process -Name "AppName" -ErrorAction SilentlyContinue)) {
        $DateTime = (Get-Date)
        Add-Content $LogFile "$DateTime - AppName started successfully"
    }
    Else {
        $DateTime = (Get-Date)
        Add-Content $LogFile "$DateTime - AppName failed to start"
    }
}
Else {
    $DateTime = (Get-Date)
    Add-Content $LogFile "$DateTime - AppName already running"
}
