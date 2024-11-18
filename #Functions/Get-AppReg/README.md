This function pulls app details from the following registry keys and outputs the results. It must be run in 64bit context to ensure both keys are treated separately
<br>
<br>
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
<br>
HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
<br>
<br>
Use the following parameters to single out required app(s)
<br>
[Mandatory] `-AppNameLike`
<br>
[Optional] `-AppNameNotLike`, `-PublisherLike`
<br>
<br>
-Like and -NotLike parameters can use wildcards to cover any uncertainties or variations in the app display name
<br>
-AppNameNotLike is configured to accept a single value or an array of strings
<br>
**When called, the function should be encapsulated in an array to allow the results to be indexed**
<br>
<br>
Example 1

    $AppNameReg = @(Get-AppReg -AppNameLike "*Remote*Desktop*" -PublisherLike "*Microsoft*")

Example 2

    $AppNameReg = @(Get-AppReg -AppNameLike "*Dropbox" -AppNameNotLike "*Helper*")

Example 3

    $AppNameReg = @(Get-AppReg -AppNameLike "*Acrobat*Acrobat*" -AppNameNotLike @("*Refresh*Manager*","*Customization*Wizard*"))
