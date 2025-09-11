$Source = "C:\Software\Firefox"
$MSIFiles = @(Get-ChildItem -Recurse -Path $Source -Filter "*.msi*" | Where-Object {$_.Name -like "*Firefox*"})
$RequiredVersion = [version]"131.0.2.0"

Foreach($MSIFile in $MSIFiles) {
$MSIversion = [version](Get-MSIProperty productversion -Path $MSIFile.Fullname).value
    if($MSIVersion -eq $RequiredVersion) {
        $MSIToInstall = $MSIFile.FullName
    }
}

Start-Process MSIExec.exe -Wait -ArgumentList "/i $MSIToInstall /qn"
