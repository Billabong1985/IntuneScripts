$mstemplates = "$env:USERPROFILE\Documents\Custom Office Templates"
$currentfiles = "$PSScriptRoot\Templates\Current"
$archivedfilelist = "$PSScriptRoot\Templates\Archived\Archived.txt"
$logfolder = "C:\Software\DocumentTemplates"
$logfile = "$logfolder\RemoveTemplates.log"
$copylogfile = "$logfolder\CopyTemplates.log"

#Check if log file exists, clear content if it does
If(test-path $logfile)
    {
    Clear-Content $logfile
    }   
#Check if log folder exists, create it if not
 If(!(test-path $logfolder))
    {
    New-Item -ItemType Directory -Force -Path $logfolder
    }   
#Check if log file exists, create it if not
If(!(test-path $logfile))
    {
    New-Item $logfile
    }

#Check each current source template file to see if it is present at the destination,
#remove if it is and write to log file
$currentfilenames = (get-childitem $currentfiles -attribute !directory -name)
foreach ($currentfilename in $currentfilenames)
    {
    if (test-path $mstemplates\$currentfilename)
        {
        remove-item -path $mstemplates\$currentfilename -force
        $datetime = (Get-Date)
        add-content $logfile "$datetime - $currentfilename successfully deleted"
        }
    }

#Compare archived file list against current destination file list,
#delete any that have been listed as archived and write to log file
$archivedfilenames = (get-content $archivedfilelist)
foreach ($archivedfilename in $archivedfilenames)
    {
    if (test-path $mstemplates\$archivedfilename)
        {
        Remove-Item $mstemplates\$archivedfilename -Force
        $datetime = (Get-Date)
        add-content $logfile "$datetime - $archivedfilename successfully deleted"
        }
    }

#Check if CopyTemplates.log exists, delete if it does
if(test-path $copylogfile)
    {
    Remove-Item $copylogfile -Force
    }
