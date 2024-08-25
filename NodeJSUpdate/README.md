These scripts were written following a Microsoft vulnerability report citing several different versions of NodeJS where I had several affected developers with different major versions and needed to patch the vulnerability, but not force all users onto the latest major build as this could interfere with development work, and also not force an update on anyone who was not running a version flagged as vulnerable

Updates were pushed through Intune so needed a requirement script to only target vulnerable versions, an install script to only update those vulnerable versions to a newer safe major version, and a detection script. MSI files need to be downloaded for versions that may need updating, and nesting in a subfolder of the script root

DetectNodeJSVulnerability.ps1 checks registry for currently installed versions and compares to an array of 'Safe' versions based on major version number to determine if a machine has any versions that need updating

InstallNodejs.ps1 creates an array of filenames and versions from MSI files placed in a subfolder, checks registry for any installed versions and matches them to the respective safe version and package based on major version number, then installs the matching package for any that are an older version than the matched safe version

DetectNodejsVersion.ps1 checks registry for currently installed versions and compares them to an array of verions matched to the MSI files used in the install script, based on major version number, then writes a true or false value for each matched install to an object array. This array then returns a success if no false values are present

The scripts could easily be changed to work with any other similar situation of another piece of software that may have users running multiple different versions and a blanket upgrade isn't suitable, by simply changing the registry search criteria
