$logfile = "C:\Software\DocumentTemplates\CopyTemplates.log"
$success = "Template Collection V1.0.0 - All files present"

if ((get-content $logfile | select-string $success))
    {
    Write-Host Success
    }
