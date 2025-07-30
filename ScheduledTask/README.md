The CMD task action used in this scheduled task is designed to hide the Powershell pop-up window that the user would usually see if calling a script natively

Any script can be used with the scheduled task, the example here is for checking whether a specific app is running each day and starting it if not, useful for cases where users do not regularly reboot their laptops and an app falling over could cause issues, this ensures every day that the app is running

The versioning is used to allow Intune to detect any changes to both the task settings and script file and update accordingly
