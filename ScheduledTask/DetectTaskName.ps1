#Define expected versions
$TaskVersion = "V1.0"
$ScriptVersion = "V1.0"

#Define variables
$TaskName = "TaskName"
$ScriptFolder = "C:\Software\TaskFolder"
$ScriptFile = "$ScriptFolder\TaskScript.ps1"

#Get the description of the scheduled task, this should be the version number
$TaskDescription = (Get-ScheduledTask -TaskName $TaskName -ErrorAction Ignore).Description

if (($TaskDescription -eq $TaskVersion) -and (get-content $ScriptFile -ErrorAction Ignore | Select-String ($ScriptVersion))) {
    Write-Host "Configured"
    Exit 0
}
