#Set variables for folders and files. TaskScriptVersion value needs to be commented in the task script file
$LogFolder = "C:\Software\RemoveAppxPackages"
$LogFile = "$LogFolder\CreateScheduledTask.log"
$TaskScript = "RemoveAppxPackages.ps1"
$TaskScriptVersion = "V1.4"

#Set Variables for the task
$TaskName = "RemoveAppxPackages"
$TaskDescription = "V1.0"
$ExistingTask = (Get-ScheduledTask -TaskName $TaskName -ErrorAction Ignore)
$Trigger = New-ScheduledTaskTrigger -AtLogOn
#$username = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object UserName).UserName
#$principal = New-ScheduledTaskPrincipal -UserId $username
$Principal = New-ScheduledTaskPrincipal -GroupId Users
$Ascii = ([char]34)
$Action = New-ScheduledTaskAction -Execute cmd.exe -Argument "cmd /c start /min $Ascii$Ascii powershell -Windowstyle Hidden -ExecutionPolicy Bypass -File $LogFolder\$TaskScript"
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable

#Check for log folder and file, clear content if it already exists
if (!(Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Force -Path $LogFolder
}
Clear-Content $LogFile -ErrorAction Ignore

Start-Transcript -Path $LogFile

#If the script file does not exist or version number does not match, copy it
if (!(get-content "$LogFolder\$TaskScript" -ErrorAction Ignore | Select-String ($TaskScriptVersion))) {
    Copy-Item ".\$TaskScript" -Destination $LogFolder -Force
}

#If the scheduled task does not already exist, create it
if ($null -eq $ExistingTask) {
    Register-ScheduledTask -TaskName $TaskName -Description $TaskDescription -Trigger $Trigger -Principal $Principal -Action $Action -Settings $Settings
}

#If the scheduled task already exists but the version number does not match, update it
if(($null -ne $ExistingTask) -and ($ExistingTask.Description -ne $TaskDescription)) {
    $ExistingTask.Description = $TaskDescription
    $ExistingTask | Set-ScheduledTask
    Set-ScheduledTask -TaskName $TaskName -Trigger $Trigger -Principal $Principal -Action $Action -Settings $Settings
}

Stop-Transcript



if (!(get-content "$LogFolder\$TaskScript" -ErrorAction Ignore | Select-String ($TaskScriptVersion))) {
    Write-host "no match"
}
