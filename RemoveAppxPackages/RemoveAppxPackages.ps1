<#
RemoveAppxPackages Script v1.4
#>

#Set variables
$LogFolder = "C:\Software\RemoveAppxPackages"
$LogFile = "$LogFolder\RemoveAppxPackages.log"

#Check for log folder and file, clear content if it already exists
if (!(Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Force -Path $LogFolder
}
Clear-Content $LogFile -ErrorAction Ignore

#Create search strings array for apps to remove
$packages = @(
    "people",
    "xbox",
    "gaming",
    "phone",
    "mcafee",
    "3d",
    "reality",
    "onenote",
    "office",
    "microsoftteams",
    "skype",
    "communicat",
    "help",
    "feedback",
    "onedrive",
    "solitaire",
    "getstarted",
    "wallet",
    "news",
    "maps"
)

#Create exceptions array, for apps that match the package search strings 
#but cannot be removed with this command and will always error
$exceptions = @(
    "Microsoft.Windows.PeopleExperienceHost",
    "Microsoft.XboxGameCallableUI"
)

Start-Transcript -Path $logfile

#Attempt to remove each package in the array if found and not in exceptions array
foreach ($package in $packages) {
    $packagename = (get-appxpackage *$package*)
    if ((($packagename).Name -notin $exceptions) -and ($null -ne $packagename)) {
        Write-Host Attempting to remove package: (Get-Appxpackage *$package*)
        $packagename | Remove-AppxPackage
    }
}

Stop-Transcript
