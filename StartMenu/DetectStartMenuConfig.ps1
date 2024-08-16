$logfile = "C:\Software\StartMenu\StartMenuConfig.log"
$failure = "incorrect value","not present"
$status = Get-Content $logfile | select-string ($failure)

if($null -eq $status)
    {
    write-host Success
    }
