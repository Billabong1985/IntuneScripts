function Set-Regkeys
{
param(
    [Parameter(Mandatory=$true)]
    [string]$CsvImport,
    [Parameter(Mandatory=$false)]
    [string]$LogResults
    )

#Create an array of reg keys from an imported CSV file
$regkeys = Import-Csv $CsvImport

#Execute commands on each key imported
foreach ($reg in $regkeys)
    {
    #If the reg key does not already exist, create it
    if(!(Get-Item -Path $reg.key -ErrorAction SilentlyContinue))
        {
        New-Item -Path $reg.key
        }
    #If the reg value does not already exist, create it
    if(!(Get-ItemProperty -Path $reg.key -Name $reg.name -ErrorAction SilentlyContinue))
        {
        New-ItemProperty -Path $reg.key -Name $reg.name -Value $reg.value  -PropertyType $reg.type
        }
    #If the existing reg value does not match the array, update it
    if(((Get-ItemProperty -Path $reg.key -Name $reg.name).($reg.name)) -ne $reg.value)
        {
        Set-ItemProperty -Path $reg.key -Name $reg.name -Value $reg.value
        }
    }

#If a log file parameter was passed, check values and log results
If($PSBoundParameters.ContainsKey("LogResults"))
    {
    foreach ($reg in $regkeys)
        {
        $regcheck = ((Get-ItemProperty -Path $reg.key -Name $reg.name).($reg.name))
        #If reg entry is present and matches required value
        if(($null -ne $regcheck) -and ($regcheck -eq $reg.value))
            {
            $datetime = (Get-Date)
            Add-Content $LogResults "$datetime - $reg present and set to correct value"
            }
        #If reg entry is present but does NOT match required value
        if(($null -ne $regcheck) -and ($regcheck -ne $reg.value))
            {
            $datetime = (Get-Date)
            Add-Content $LogResults "$datetime - $reg present but set to incorrect value"
            }
        #If reg entry is not present
        if($null -eq $regcheck)
            {
            $datetime = (Get-Date)
            Add-Content $LogResults "$datetime - $reg not present"
            }
        }
    }
}
