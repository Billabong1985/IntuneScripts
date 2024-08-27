This function pulls all app details from the following registry keys and outputs the results
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
<br>
<br>
Use the following parameters to single out required app(s)

[Mandatory] `-AppNameLike`

[Optional] `-AppNameNotLike`, `-PublisherLike`
<br>
<br>
-Like and -NotLike parameters can use wildcards to cover any uncertainties or variations in the app display name
-AppNameNotLike is configured to accept a single value or an array of strings
<br>
<br>
Example 1

    Get-AppReg -AppNameLike "*Remote*Desktop*" -PublisherLike "*Microsoft*"

Example 2

    Get-AppReg -AppNameLike "*Dropbox" -AppNameNotLike "*Helper*"

Example 3

    Get-AppReg -AppNameLike "*Acrobat*Acrobat*" -AppNameNotLike @("*Refresh*Manager*","*Customization*Wizard*")
