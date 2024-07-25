This Script is designed to copy MS Office tmeplate files into the user's default personal custom templates folder, as such when packaged as a Win32 App, it should be run in the user context. It has been written for packaging and distributing with Intune, but should work for other deployment methods with minimal adjustments. 

Intune detection script is included to read the created log file and check the version number printed in it

All required template files should be dropped in the \Templates\Current folder

When new versions of template files are ready to be distributed, or old ones retired, follow the below steps
1) Copy the full file name(s) of the template file(s) to be retired (including the .dotx/.potx extension)
2) Paste the file name(s) onto a new line in the \Templates\Archived\Archived.txt file
3) Ensure no spurious spaces at the beginning or end of the new line and save the updated Archived.txt file
5) Delete the file being retired from \Templates\Current
6) Add any new file versions to \Templates\Current, ensuring they have different file names to the old ones so they are not confused with the archived list
7) Edit the copytemplates.ps1 script, update the final log file write with a new version number
8) Edit the DetectDocumentTemplates.ps1 script to search for the new version number in the log file

This should ensure that the script will re-run, retired files will be deleted from user's machines and new ones added
