###################################################################
#                                                                 #
# Configures Windows start menu layouts by editing registry       #
#                                                                 #
# Registry keys are built into an array with pscustomobject       #
#                                                                 #
# Additional keys can be added to the config by copy/pasting the  #
# format of the pscustomobjects in the array                      #
#                                                                 #
###################################################################

#Set variables
$winver = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
$logfolder = "C:\Software\StartMenu"
$logfile = "$logfolder\StartMenuConfig.log"

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


#Build registry keys array if Windows 10
if ($winver -like '*Windows 10*')
{
$regkeys = @(
[pscustomobject]@{
    Key = "HKCU:\Software\Microsoft\Windows\ContentDeliveryManager"
    Name = "SubscribedContent-338388Enabled"
    Type = "DWORD"
    Value = "0"
    }
    )
}

#Build registry keys array if Windows 11
if ($winver -like '*Windows 11*')
{
$regkeys = @(
[pscustomobject]@{
    Key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Name = "TaskbarAl"
    Type = "DWORD"
    Value = "0"
    }
[pscustomobject]@{
    Key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Name = "TaskbarMn"
    Type = "DWORD"
    Value = "0"
    }
[pscustomobject]@{
    Key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Name = "TaskbarDa"
    Type = "DWORD"
    Value = "0"
    }
[pscustomobject]@{
    Key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Name = "ShowTaskViewButton"
    Type = "DWORD"
    Value = "0"
    }
[pscustomobject]@{
    Key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Name = "Start_IrisRecommendations"
    Type = "DWORD"
    Value = "0"
    }
    )
}

#Run commands against each registry key in the array
foreach ($reg in $regkeys)
    {
    #If the reg key does not already exist, create it
    if(!(Get-ItemProperty -Path $reg.key -Name $reg.name))
        {
        New-ItemProperty -Path $reg.key -Name $reg.name -Value $reg.value  -PropertyType $reg.type
        }
    #If the existing reg key value does not match the array, update it
    if(((Get-ItemProperty -Path $reg.key -Name $reg.name).($reg.name)) -ne $reg.value)
        {
        Set-ItemProperty -Path $reg.key -Name $reg.name -Value $reg.value
        }
    }
 
#Check registry entries were correctly created and set, and write to log file
foreach ($reg in $regkeys)
        {
        $regcheck = ((Get-ItemProperty -Path $reg.key -Name $reg.name).($reg.name))
            #If reg entry is present and matches required value
            if(($regcheck -ne $null) -and ($regcheck -eq $reg.value))
            {
            $datetime = (Get-Date)
            Add-Content $logfile "$datetime - $reg present and set to correct value"
            }
            #If reg entry is present but does NOT match required value
            if(($regcheck -ne $null) -and ($regcheck -ne $reg.value))
            {
            $datetime = (Get-Date)
            Add-Content $logfile "$datetime - $reg present but set to incorrect value"
            }
            #If reg entry is not present
            if($regcheck -eq $null)
            {
            $datetime = (Get-Date)
            Add-Content $logfile "$datetime - $reg not present"
            }
        }  
