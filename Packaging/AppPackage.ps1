######################################################################################
#                                                                                    #
# Streamlines Intune app packaging by prompting for a source file then running the   #
# packaging utility on the selected file                                             #
#                                                                                    #
# $packagingfolder variable must be manually set to the source of the folders/files  #
# All other variables are dynamic                                                    #
#                                                                                    #
# This script assumes folder structure is organised into named app folders with a    #
# subfolder named 'Source' under each one which contains installation file(s).       #
# All folders and subfolders should use names which do NOT include spaces            #
#                                                                                    #
# It also assumes that the "IntuneWinAppUtil.exe" file is in the root of the folder  #
#                                                                                    #
# All packages will be saved to a 'Package' folder under the respective app folder   #
#                                                                                    #
######################################################################################


#Set the location of the top level packaging folder
$packagingfolder = "$ENV:UserProfile\Axian Dropbox\IT\Software\Scripts\packaging"

#Set the script run location to the packaging folder
set-location -path $packagingfolder

#Check that the IntuneWinAppUtil.exe file is in the root of the folder, cancel script if it is not
if(!(test-path "$packagingfolder\IntuneWinAppUtil.exe"))
    {
    Write-Output ""
    Write-Output "IntuneWinAppUtil.exe not found, please ensure this file is placed in the top level of the packaging folder and try again"
    Break
    }

# Select App folder from list
# Load assembly for OpenFileDialog
Add-Type -AssemblyName System.Windows.Forms

# Create an OpenFileDialog object
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog

# Set the initial directory and filter
$fileDialog.InitialDirectory = "$packagingfolder"
$fileDialog.Filter = "All files (*.*)|*.*"
# Show the OpenFileDialog
$result = $fileDialog.ShowDialog()

if ($result -eq "OK") 
    {
    # Get the selected file
    $selectedFile = $fileDialog.FileName
    }

# Set the variables required for app packaging
$sourcefolder = (split-path -Path $selectedfile -Parent) -replace [regex]::Escape($packagingfolder), '.'
$installfile = $selectedFile -replace [regex]::Escape($packagingfolder), '.'
$outputfolder = $sourcefolder -replace "Source","Package"

# Set the arguments for the packaging process
$arguments = "-c $sourcefolder -s $installfile -o $outputfolder -q"
# Start the packaging process using set variables
Start-Process IntuneWinAppUtil.exe -ArgumentList $arguments
