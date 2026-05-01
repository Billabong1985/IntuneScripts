The CMD task action used in this scheduled task is designed to hide the Powershell pop-up window that the user would usually see if calling a script natively

Any script can be used with the scheduled task, the example here is for checking whether a specific app is running each day and starting it if not, useful for cases where users do not regularly reboot their laptops and an app falling over could cause issues, this ensures every day that the app is running

Version numbers are used to allow Intune detection of the current version of both the scheduled task
and the associated run script. These must match up so that new versions are properly deployed and Intune
correctly detects the latest version

Maintain single decimal version number convention (e.g. 1.5 OK, 1.4.5 NOT OK) for consistency

If updating StartDropbox.ps1, version number must be changed in...
<br>The comment at the top of the script
<br>The $TaskScriptVersion variable in CreateScheduledTask.ps1
<br>The $ScriptVersion variable in DetectStartDropbox.ps1
<br>

If updating CreateScheduledTask.ps1, version number must be changed in...
<br>The $TaskDescription variable in the script
<br>The $TaskVersion variable in DetectStartDropbox.ps1
