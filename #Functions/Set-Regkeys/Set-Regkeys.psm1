function Set-RegKeys {
    #Define the parameters
    param(
        [Parameter(Mandatory = $true)]
        [string]$CsvImport,
        [Parameter(Mandatory = $false)]
        [string]$LogResults
    )

    #Create an array of reg keys from an imported CSV file
    $RegKeys = Import-Csv $CsvImport

    #Execute commands on each key imported
    foreach ($Reg in $RegKeys) {
        #If the reg key does not already exist, create it
        if (!(Get-Item -Path $Reg.Key -ErrorAction SilentlyContinue)) {
            New-Item -Path $Reg.Key -Force
        }
        #If the reg value does not already exist, create it
        if (!(Get-ItemProperty -Path $Reg.Key -Name $Reg.Name -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $Reg.Key -Name $Reg.Name -Value $Reg.Value  -PropertyType $Reg.Type -Force
        }
        #If the existing reg value does not match the array, update it
        if (((Get-ItemProperty -Path $Reg.Key -Name $Reg.Name).($Reg.Name)) -ne $Reg.Value) {
            Set-ItemProperty -Path $Reg.Key -Name $Reg.Name -Value $Reg.Value -Force
        }
    }

    #If a log file parameter was passed, check values and log results
    If ($PSBoundParameters.ContainsKey("LogResults")) {
        #Create the log folder if it does not already exist
        $LogResultsPath = Split-Path $LogResults -Parent
        If (!(Test-Path $LogResultsPath)) {
            New-Item -ItemType Directory -Force -Path $LogResultsPath
        }
        #Check the keys and write to the log file
        foreach ($Reg in $Regkeys) {
            $RegCheck = ((Get-ItemProperty -Path $Reg.Key -Name $Reg.Name).($Reg.Name))
            #If reg entry is present and matches required value
            if (($null -ne $RegCheck) -and ($RegCheck -eq $Reg.Value)) {
                $DateTime = (Get-Date)
                Add-Content $LogResults "$DateTime - $Reg present and set to correct value"
            }
            #If reg entry is present but does NOT match required value
            if (($null -ne $RegCheck) -and ($RegCheck -ne $Reg.Value)) {
                $DateTime = (Get-Date)
                Add-Content $LogResults "$DateTime - $Reg present but set to incorrect value"
            }
            #If reg entry is not present
            if ($null -eq $RegCheck) {
                $DateTime = (Get-Date)
                Add-Content $LogResults "$DateTime - $Reg not present"
            }
        }
    }
}
