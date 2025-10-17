# Define variables
$CurrentUser = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName).Split('\')[-1]
$WinVer = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
$LogFolder = "C:\Software\StartMenu"
$Success = $false

# Define the expected log file if the OS is Windows 10
if ($WinVer -like '*Windows 10*') {
    $LogFile = "$LogFolder\Win10StartMenuConfig$CurrentUser.log"
}

# Define the expected log file if the OS is Windows 11
if ($WinVer -like '*Windows 11*') {
    $LogFile = "$LogFolder\Win11StartMenuConfig$CurrentUser.log"
}

# Check whether the log file exists, exit with fail code if not
If ((Test-Path $LogFile) -eq $False) {
    Write-Host "Log file not found"
    Exit 1
}
# Check for keywords indicating failures
$FailureKeywords = "incorrect value", "not present"
$KeywordSearch = Select-String -Path $LogFile -Pattern $FailureKeywords

# If no failure keywords were found, change the success flag to true
If ($null -eq $KeywordSearch) {
    $Success = $true
}

# Success has been set as true, output a success exit code, otherwise output a failure exit code
if ($Success -eq $true) {
    Write-host Success
    Exit 0
}
Else {
    Exit 1
}
