#Check whether all customisation registry keys are present and set correctly
#Create array of reg keys
$RegKeys = @(
    [pscustomobject]@{ Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"; Name = "HiberbootEnabled"; Type = "DWORD"; Value = "0" }
 )

#Count how many reg keys are in the array
$KeyCount = $RegKeys.Count
#Set the success count to an initial value of 0
$SuccessCount = 0
#For each key value in the array, compare to the system registry and add 1 to the count if it matches
foreach ($Reg in $RegKeys) {
    if (((Get-ItemProperty -path $Reg.Key -name $Reg.Name -ErrorAction SilentlyContinue).($Reg.Name)) -eq $Reg.Value) {
        $SuccessCount ++
    }
}

#If the success count matches the count of keys in the array, set variable as true
if ($SuccessCount -eq $KeyCount) {
    $SettingsApplied = $true
}
else {
    $SettingsApplied = $false
}

#Output results
if($SettingsApplied -eq $true) {
    Write-Host "Success"
    Exit 0
}
