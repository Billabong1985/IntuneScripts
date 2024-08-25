These scripts were written following a Microsoft vulnerability report citing several different versions of NodeJS where I had several affected developers with different major versions and needed to patch the vulnerability,
but not force all users onto the latest major build as this could interfere with development work, and also not force an update on anyone who was not running a version flagged as vulnerable

Updates were pushed through Intune so needed a requirement script to only target vulnerable versions, an install script to only update those vulnerable versions to a newer safe major version, and a detection script

DetectNodeJSVulnerability.ps1 checks registry for currently installed versions and ocmpared to an array of 'Safe' versions to determine if the machine needs updating
InstallNodejs.ps1 creates an array of filenames and versions from MSI files placed in a subfolder and compares any currently installed versions to that array, so only the relevant version is installed
DetectNodejsVersion.ps1 checks registry for currently installed versions and compares them to an array of verions matched to the MSI files used in the install script

The scripts could easily be changed to work with any other similar situation of another piece of software that may have users running multiple different versions and a blanket upgrade isn't suitable by simply changing the version numbers and registry search criteria
