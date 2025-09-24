$CurrentUser = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName).Split('\')[-1]
$LogFolder = "C:\Software\StartMenu"
$LogFile = "$LogFolder\StartMenuConfig$CurrentUser.log"
$Failure = "incorrect value","not present"
$Status = Get-Content $LogFile | select-string ($Failure)

if($null -eq $Status)
    {
    write-host Success
    }
