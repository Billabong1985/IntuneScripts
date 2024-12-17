<#
Prompts for a file within a specified  folder tree

Returns the file version number of the file selected
#>

# Set the source folder
$sourcefolder = "$ENV:UserProfile\Axian Dropbox\IT\Software\Scripts\packaging"

# Load assembly for OpenFileDialog
Add-Type -AssemblyName System.Windows.Forms

# Create an OpenFileDialog object
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog

# Set the initial directory and filter
$fileDialog.InitialDirectory = $sourcefolder # replace with your fixed path
$fileDialog.Filter = "All files (*.*)|*.*"

# Show the OpenFileDialog
$result = $fileDialog.ShowDialog()

if ($result -eq "OK") 
    {
    # Get the selected file
    $selectedFile = $fileDialog.FileName
    }

# Check that the selected file is an EXE or MSI
if(($selectedFile -like "*.msi") -or ($selectedFile -like "*.exe"))
    {
    # If selected file is an MSI, set variables
    if($selectedfile -like "*.msi")
        {
        $MSIFile = split-path -Path $selectedfile -Leaf
        $MSIPath = split-path -Path $selectedfile -Parent
        $productname = (Get-MSIProperty productname -Path $selectedfile).value

        # Retrieve version number of MSI file
        if($productname -like "*Google*Chrome*")
            {
            $comment = (Get-MSISummaryInfo $selectedfile).comments
            $MSIversion = $comment.trimend().split(" ")[0]
            }
            else
            {
            $MSIversion = (Get-MSIProperty productversion -Path $selectedfile).value
            }

        # Display the file version
        write-output ""
        write-output "File: $MSIfile"
        write-output "Path: $MSIPath"
        write-output "Version: $MSIversion"
        }

    # If selected file is an EXE, set variables
    if($selectedfile -like "*.exe")
        {
        $EXEFile = split-path -Path $selectedfile -Leaf
        $EXEPath = split-path -Path $selectedfile -Parent

        # Retrieve version number of the .exe file
        $EXEVersion = (Get-Item $selectedfile).VersionInfo.FileVersion

        # Display the file version
        write-output ""
        write-output "File: $EXEfile"
        write-output "Directory: $EXEPath"
        write-output "Version: $EXEversion"
        }
    }
 else
    # Report if the selected file is not an EXE or MSI
    {
    Write-Output ""
    Write-Output "Selected file is not an EXE or MSI, or no file was selected."
    }
