This function pulls all app details from the following registry keys and outputs the results
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall

Use the following parameters to single out required app(s)
[Mandatory] -AppNameLike
[Optional] -AppNameNotLike, -PublisherLike, -InstallPathEq

Like and NotLike parameters can use wildcards to cover any uncertainties or variations in the app display name, 
e.g. -AppNameLike "*Adobe*Acrobat*"