<#
Function to download files, works with Invoke-WebRequest or AWS S3 download commands
For downloading entire contents of an S3 folder, a source file list will need to be stored in an array and a foreach loop used to grab each file
DownloadCommand expects a full download string, e.g. Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\Temp\AWSCLIV2.msi" -Verbose
The string can be built dynamically from variables but must be passed in full to the DownloadCommand variable
#>

#Set the parameters
function Download-Files {
    param (
        [string]$FileName,
        [string]$Destination,
        [string]$DownloadCommand
    )

    # Log the start time of the download attempt
    Write-Host "`n$(Get-Date): Started downloading $FileName"
    $DownloadAttempt = 1
    $MaxAtttempts = 5
    $IsDownloaded = $False

    # Start the while loop to enable retries of failed downloads
    while (($DownloadAttempt -lt $MaxAtttempts) -and (-not $IsDownloaded)) {
        # Invoke the download command string
        Invoke-Expression $DownloadCommand
        # Check whether the download completed, write output, retry if if failed
        $IsDownloaded = (Test-Path $Destination\$FileName)
        If ($IsDownloaded) {
            Write-Host "$(Get-Date): $FileName download completed"
        }
        else {
            $DownloadAttempt ++
            Write-Host "$(Get-Date): $FileName not downloaded, retrying... (Attempt $($DownloadAttempt))"
        }
        If (($DownloadAttempt -eq $MaxAtttempts) -and (-not $IsDownloaded)) {
            Write-Host "$(Get-Date): $FileName failed to download after $MaxAtttempts attempts."
        }
    }
}
