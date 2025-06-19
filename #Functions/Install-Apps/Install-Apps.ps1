<# 
Functions for installing apps with inbuilt checks and retries
The Get-AppReg function is used to check for successful installation
App details should be input using a pscustomobject in the below format
Additional parameters can be added if needed for additional commands that will be run against the object
Multiple apps can be saved in an array and called with a foreach command, or single apps can be called from a single pscustomobject
This function assumes that the CommandArgs property has a log file output switch as the last part of the string

$AppToInstall =
    [PSCustomObject]@{
        Name           = "App Name"
        FilePath       = "$folder\installer.msi"
        Command        = "msiexec.exe"
        CommandArgs    = "/i $folder\installer.msi /quiet /norestart /L*v"
        AppRegNameLike = "*App*Name*"
    }
#>

# Create the Get-AppReg function for checking installation status
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


# Create the Install-Apps function for starting installs with checks and retries
function Install-Apps {
    param (
        [PSCustomObject]$App,
        [string]$LogFolder
    )

    # Set the initial value for the install count
    $InstallCount = 0

    # Start the loop to attempt install
    while ($InstallCount -lt 3) {
        # Increase the install count, define the log file and write output
        $InstallCount++
        $LogFile = "$LogFolder\$($App.Name -replace ' ', '_')-Install-$InstallCount.log"
        Write-Host "`n$(Get-Date): Attempting Install of $($App.Name) (Attempt $InstallCount)"
                
        # Check the installation file exists, cancel install if it doesn't
        if (!(Test-Path $($App.FilePath))) {
            Write-Host "$(Get-Date): Installation file not found: $($App.FilePath). Exiting installation process."
            break
        }
        
        # If the install is an MSI, check for MSI Mutex availability
        If ($App.FilePath -like "*.msi") {
            $MutexName = "Global\_MSIExecute"
            Write-Host "$(Get-Date): Checking if MSI mutex ($MutexName) is available..."
            try {
                $mutex = [System.Threading.Mutex]::OpenExisting($MutexName)
                $mutex.Close()
                $mutexHeld = $true
                Write-Host "$(Get-Date): MSI mutex is currently held by another process."
            }
            catch {
                $mutexHeld = $false
                Write-Host "$(Get-Date): MSI mutex is available."
            }
            # If the MSI Mutex is held, kill msiexec processes to free it
            if ($mutexHeld) {
                Write-Host "$(Get-Date): Stopping MSI processes to free up the mutex..."    
                Write-Host "$(Get-Date): Checking for running MSI processes..."
                $msiProcesses = Get-Process -Name "msiexec" -ErrorAction SilentlyContinue
                if ($msiProcesses) {
                    Write-Host "$(Get-Date): Found MSI processes. Attempting to stop them..."
                    foreach ($process in $msiProcesses) {
                        try {
                            Stop-Process -Id $process.Id -Force
                            Write-Host "$(Get-Date): Stopped MSI process with ID $($process.Id)."
                        }
                        catch {
                            Write-Host "$(Get-Date): Failed to stop MSI process with ID $($process.Id)."
                        }
                    }
                }
                else {
                    Write-Host "$(Get-Date): No MSI processes found."
                }
            }
        }

        try {
            # Start the installation process
            Start-Process $App.Command -Wait -ArgumentList "$($App.CommandArgs) $LogFile"
            # Check the registry to verify installation
            $IsInstalled = Get-AppReg -AppNameLike $App.AppRegNameLike
            if ($IsInstalled) {
                Write-Host "$(Get-Date): $($App.Name) Successfully Installed"
                break
            }
            else {
                Write-Host "$(Get-Date): Installation not completed, retrying..."
                Start-Sleep -Seconds 10
            }
        }
        catch {
            Write-Host "$(Get-Date): An error occurred during installation: $_"
        }
    }
    # Final output if installation fails after 3 attempts
    if ($InstallCount -eq 3 -and -not $IsInstalled) {
        Write-Host "$(Get-Date): Installation of $($App.Name) failed after 3 attempts"
    }
}
