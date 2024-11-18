This script is for deployment of the offline installer of Adobe Reader found at the below URL. This was written for Intune but should require minimal modification for other deployment methods. The downloaded file name is usually in the format "AcroRdrDC**VERSION**_MUI.exe", the $Package variable should pick this up but check in case name format has changed
<br>
https://get.adobe.com/uk/reader/enterprise/
<br>
<br>
Adobe offer a customization wizard app that is intended for enterprise deployments of Adobe Reader, but it requires the downloaded package file to be extracted and I have consistently found it to just be awkward to use, so created a script to install directly from the downloaded file and apply the same customizations I was doing in the wizard via registry edits. Details of other customizations which can be made via registry can be found at the below URL
<br>
https://www.adobe.com/devnet-docs/acrobatetk/tools/PrefRef/Windows/FeatureLockDown.html
