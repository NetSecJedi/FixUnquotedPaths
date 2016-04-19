# FixUnquotedPaths
A Powershell Script to fix unquoted service paths in Windows

 Original Code Author: Jeff Liford
 
 Modified by: Seth Feaganes (@NetSecJedi)
 
 Link to Original: http://www.ryanandjeffshow.com/blog/2013/04/11/powershell-fixing-unquoted-service-paths-complete/

 A powershell script which will search the registry for unquoted service paths and properly quote
 them. If run in a powershell window exclusively, this script will produce no output other than
 a line with "The operation completed successfully" when it fixes a bad key. Verbose output can
 be enabled by uncommenting the Write-Progress or Write-Output lines or running the original scripts
 as intended with command pipes.

 This script was modified from the original three scripts named Get-SVCPath.ps1, Find-BADSVCPath.ps1,
 and Fix-BADSVCPath.ps1 to allow it to be run as a single script on one system or for use in mass
 deployment systems such as PDQDeploy, KACE, etc for example. If you require the functionality of those
 scripts for auditing, execution over multiple systems, or any other options those scripts provide, please
 use those scripts instead. I am posting this modification as reference to something useful in situations
 where a quick fix is necessary. 

 Myself nor the original author of this code shall be held liable for any damage incurred running
 this in a production environment. Please take proper precautions before modifying the registry
 such as running this script with the REG ADD line commented out or taking a backup of the registry
 prior to running the script. Or obviously on virtual environments, etc.
