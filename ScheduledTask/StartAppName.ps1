<#
StartAppName Script V1.0

This uses a dynamic registry search to find the process's source folder
to account for programs that use versioning in their installation folder paths

For programs that do not use versioning in this way or do not return an installfolder variable,
Remove the registry search function and manually set the $AppInstallPath variable

If the registry search pulls an incomplete folder path to the executable, add the missing subfolders
to the $Executable variable, e.g. $Executable = "\bin\x64\ApppName.exe"
#>

#Define the Process Name
$ProcessName = "ProcessName"
#Define the process's executable
$Executable = "AppName.exe"

#Define the log file
$LogFolder = "C:\Software\AppName"
$LogFile = "$LogFolder\StartAppName.log"

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

#Define the app registry entry by calling the function. -AppNameNotLike is set up as an array and can accept multiple strings
$AppNameReg = @(Invoke-Expression $GetAppRegCommand)

#Define the installed path
$AppInstallPath = $AppNameReg.InstallLocation
#Define the program executable path
$ExecutionPath = "$AppInstallPath\$Executable"

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

#Check whether ProcessName is running, start it if not and write to log file
If ($null -eq (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)) {
    $DateTime = (Get-Date)
    Add-Content $LogFile "$DateTime - $ProcessName not running, attempting to start"
    Start-Process $ExecutionPath
    $AttemptCount = 0
    While (($null -eq (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)) -and $AttemptCount -lt 6) {
        Start-Sleep 5
        $AttemptCount ++
    }
    If ($null -ne (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)) {
        $DateTime = (Get-Date)
        Add-Content $LogFile "$DateTime - $ProcessName started successfully"
    }
    Else {
        $DateTime = (Get-Date)
        Add-Content $LogFile "$DateTime - $ProcessName failed to start"
    }
}
Else {
    $DateTime = (Get-Date)
    Add-Content $LogFile "$DateTime - $ProcessName already running"
}
