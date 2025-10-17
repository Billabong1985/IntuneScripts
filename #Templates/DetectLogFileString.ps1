# Define the log folder and file name
$LogFolder = "C:\Software\StartMenu"
$LogFile = "$LogFolder\StartMenuLayout.log"

# Set an initial success flag of false
$Success = $false

# Set 1 or more strings to search for in the log file
$SearchString = "String A", "String B"

# Search the log file for the expected string(s)
$Search = Select-String -Path $LogFile -Pattern $SearchString

# Choose one of the below depending on whether you searched for a string that indicates success,
# or the absense of strings indicating failure

# OPTION 1 - If the search DID find the specified string(s) indicating success, change the flag to true
If ($null -ne $StringSearch) {
    $Success = $true
}

#OPTION 2 - If the search DID NOT find the specified string(s) indicating failure, change the flag to true
If ($null -eq $StringSearch) {
    $Success = $true
}

# If success flag has been set as true, output a success exit code, otherwise output a failure exit code
if ($Success -eq $true) {
    Write-host Success
    Exit 0
}
Else {
    Exit 1
}
