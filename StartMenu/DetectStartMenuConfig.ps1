$logfile = "C:\Software\StartMenu\StartMenuConfig.log"
$failure = "incorrect value","not present"

if(((Get-Content $logfile) | select-string ($failure)) -eq $null)
    {
    write-host Success
    }
