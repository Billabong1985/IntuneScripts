#Set Variables
$mstemplates = "$env:USERPROFILE\Documents\Custom Office Templates"
$currentfiles = "$PSScriptRoot\Templates\Current"
$archivedfilelist = "$PSScriptRoot\Templates\Archived\Archived.txt"
$logfolder = "C:\Software\DocumentTemplates"
$logfile = "$logfolder\CopyTemplates.log"
$removelogfile = "$logfolder\RemoveTemplates.log"

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

#If Custom Office Templates exists as a file, delete it
if(test-path $mstemplates -PathType Leaf)
    {
    Remove-Item $mstemplates -Force
    }
#Check Custom Office Templates folder exists, create it if not
 If(!(test-path $mstemplates))
    {
    New-Item -ItemType Directory -Force -Path $mstemplates
    }  

#Check if RemoveTemplates.log exists, delete if it does
if(test-path $removelogfile)
    {
    Remove-Item $removelogfile -Force
    }

#Ensure Office has correct personal template folder locations set
if(!(Get-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\word\options" -name "PersonalTemplates"))
    {
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\word\options" -name "PersonalTemplates" -Value ”$mstemplates”  -PropertyType "String"
    }
Set-ItemProperty -path "HKCU:\Software\Microsoft\Office\16.0\word\options" -name "PersonalTemplates" -value "$mstemplates"

if(!(Get-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\powerpoint\options" -name "PersonalTemplates"))
    {
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\powerpoint\options" -name "PersonalTemplates" -Value ”$mstemplates”  -PropertyType "String"
    }
Set-ItemProperty -path "HKCU:\Software\Microsoft\Office\16.0\powerpoint\options" -name "PersonalTemplates" -value "$mstemplates"

#Check each current source template file to see if it is already present at the destination,
#copy any missing files and write to log file
$currentfilenames = (get-childitem $currentfiles -attribute !directory -name)
foreach ($currentfilename in $currentfilenames)
    {
    if (test-path $mstemplates\$currentfilename)
        {
        $datetime = (Get-Date)
        add-content $logfile "$datetime - $currentfilename not copied, file already present"
        }
    if (!(test-path $mstemplates\$currentfilename))
        {
        copy-item -path $currentfiles\$currentfilename -Destination $mstemplates -force
        $datetime = (Get-Date)
        add-content $logfile "$datetime - $currentfilename successfully copied"
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
       
#Compare local templates folder to source files list, count number of files that have matching names with source file list
$sourcecount = (Get-ChildItem $currentfiles -attribute !directory -name | measure-object).count
$successcount = 0
$destinationfilelist = Get-ChildItem $mstemplates -attribute !directory -name
foreach($destinationfilename in $destinationfilelist)
    {
    if ($currentfilenames | select-string $destinationfilename)
        {
        $successcount ++
        }
    }

#Write results to log file
if($successcount -eq $sourcecount)
    {
    $datetime = (Get-Date)
    add-content $logfile "$datetime - Document Template Collection V1.0.0 - All files present"
    }

if($successcount -lt $sourcecount)
    {
    $datetime = (Get-Date)
    add-content $logfile "$datetime - Document Template Collection V1.0.0 - Some files were not copied"
    }
