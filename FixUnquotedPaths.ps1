	#####################################################################################################
	## Code Author: Jeff Liford
	## Modified by: Seth Feaganes (@Net_Sec_Jedi)
	## Original: http://www.ryanandjeffshow.com/blog/2013/04/11/powershell-fixing-unquoted-service-paths-complete/
	##
	## A powershell script which will search the registry for unquoted service paths and properly quote
	## them. If run in a powershell window exclusively, this script will produce no output other than
	## a line with "The operation completed successfully" when it fixes a bad key. Verbose output can
	## be enabled by uncommenting the Write-Progress or Write-Output lines or running the original scripts
	## as intended with command pipes.
	##
	## This script was modified from the original three scripts named Get-SVCPath.ps1, Find-BADSVCPath.ps1,
	## and Fix-BADSVCPath.ps1 to allow it to be run as a single script on one system or for use in mass
	## deployment systems such as PDQDeploy, KACE, etc for example. If you require the functionality of those
	## scripts for auditing, execution over multiple systems, or any other options those scripts provide, please
	## use those scripts instead. I am posting this modification as reference to something useful in situations
	## where a quick fix is necessary. 
	##
	## Myself nor the original author of this code cannot be held liable for any damage incurred running
	## this in a production environment. Please take proper precautions before modifying the registry
	## such as running this script with the REG ADD line commented out or taking a backup of the registry
	## prior to running the script. Or obviously on virtual environments, etc.
	#####################################################################################################
	
	## Grab all the registry keys pertinent to services    
    	$result = REG QUERY "HKLM\SYSTEM\CurrentControlSet\Services" /v ImagePath /s 2>&1
	
	#Error output from this command doesn't catch, so we need to test for it...
	if ($result[0] -like "*ERROR*" -or $result[0] -like "*Denied*")
		{ #Only evals true when return from reg is exception
		#if ($progress -eq "Yes"){ Write-Progress -Id 1 -Activity "Getting keys for $computer" -Status "Connection Failed"}
		$obj = New-Object -TypeName PSObject
		#$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $computer
		$obj | Add-Member -MemberType NoteProperty -Name Status -Value "REG Failed"
		$obj | Add-Member -MemberType NoteProperty -Name Key -Value "Unavailable"
		$obj | Add-Member -MemberType NoteProperty -Name ImagePath -Value "Unavailable"
		}	
	else
		{
		#Clean up the format of the results array
		$result = $result[0..($result.length -2)] #remove last (blank line and REG Summary)
		$result = $result | ? {$_ -ne ""} #Removes Blank Lines
		$count = 0
		While ($count -lt $result.length)
			{
			$obj = New-Object -Typename PSObject
			$obj | Add-Member -MemberType NoteProperty -Name Status -Value "Retrieved"
			$obj | Add-Member -MemberType NoteProperty -Name Key -Value $result[$count]
			$pathvalue = $($result[$count+1]).Split("", 11) #split ImagePath return
			$pathvalue = $pathvalue[10].Trim(" ") #Trim out white space, left with just value data
			$obj | Add-Member -MemberType NoteProperty -Name ImagePath -Value $pathvalue
 
			########################################################################
            # Find and Fix Bad Keys for each key object
            ########################################################################
    
            # Write-Progress -Activity "Checking for bad keys: " -status "Checking $($obj.key)"
        	if ($obj.key -eq "Unavailable")
        	{ #The keys were unavailable, I just append object and continue
        	   $obj | Add-Member –MemberType NoteProperty –Name BadKey -Value "Unknown"
        	   $obj | Add-Member –MemberType NoteProperty –Name FixedKey -Value "Can't Fix"
        	   #Write-Output $obj
        	   $obj = $nul #clear $obj         
        	} #end if
        	else
        	{
            	#If we get here, I have a key to examine and fix
            	#We're looking for keys with spaces in the path and unquoted
            	#the Path is always the first thing on the line, even with embedded arguments
            	$examine = $obj.ImagePath
            	if (!($examine.StartsWith('"'))) { #Doesn't start with a quote
            		if (!($examine.StartsWith("\??"))) { #Some MS Services start with this but don't appear vulnerable
            			if ($examine.contains(" ")) { #If contains space
            				#when I get here, I can either have a good path with arguments, or a bad path
            				if ($examine.contains("-") -or $examine.contains("/")) { #found arguments, might still be bad
            					#split out arguments
            					$split = $examine -split " -", 0, "simplematch"
            					$split = $split[0] -split " /", 0, "simplematch"
            					$newpath = $split[0].Trim(" ") #Path minus flagged args
            					if ($newpath.contains(" ")){
            						#check for unflagged argument
            						$eval = $newpath -Replace '".*"', '' #drop all quoted arguments
            						$detunflagged = $eval -split "\", 0, "simplematch" #split on foler delim
            							if ($detunflagged[-1].contains(" ")){ #last elem is executable and any unquoted args
            								$fixarg = $detunflagged[-1] -split " ", 0, "simplematch" #split out args
            								$quoteexe = $fixarg[0] + '"' #quote that EXE and insert it back
            								$examine = $examine.Replace($fixarg[0], $quoteexe)
            								$examine = $examine.Replace($examine, '"' + $examine)
            								$badpath = $true
            							} #end detect unflagged
            						$examine = $examine.Replace($newpath, '"' + $newpath + '"')
            						$badpath = $true
            					} #end if newpath
            					else { #if newpath doesn't have spaces, it was just the argument tripping the check
            						$badpath = $false
            					} #end else
            				} #end if parameter
            				else
            					{#check for unflagged argument
            					$eval = $examine -Replace '".*"', '' #drop all quoted arguments
            					$detunflagged = $eval -split "\", 0, "simplematch"
            					if ($detunflagged[-1].contains(" ")){
            						$fixarg = $detunflagged[-1] -split " ", 0, "simplematch"
            						$quoteexe = $fixarg[0] + '"'
            						$examine = $examine.Replace($fixarg[0], $quoteexe)
            						$examine = $examine.Replace($examine, '"' + $examine)
            						$badpath = $true
            					} #end detect unflagged
            					else
            					{#just a bad path
            						#surround path in quotes
            						$examine = $examine.replace($examine, '"' + $examine + '"')
            						$badpath = $true
            					}#end else
            				}#end else
            			}#end if contains space
            			else { $badpath = $false }
            		} #end if starts with \??
            		else { $badpath = $false }
            	} #end if startswith quote
            	else { $badpath = $false }
            	#Update Objects
            	if ($badpath -eq $false){
            		$obj | Add-Member -MemberType NoteProperty -Name BadKey -Value "No"
            		$obj | Add-Member -MemberType NoteProperty -Name FixedKey -Value "N/A"
            		#Write-Output $obj
            		$obj = $nul #clear $obj
            	}
            	if ($badpath -eq $true){
            		$obj | Add-Member -MemberType NoteProperty -Name BadKey -Value "Yes"
            		#sometimes we catch doublequotes
            		if ($examine.endswith('""')){ $examine = $examine.replace('""','"') }
            		$obj | Add-Member -MemberType NoteProperty -Name FixedKey -Value $examine
					if ($obj.badkey -eq "Yes"){
						#Write-Progress -Activity "Fixing $($obj.computername)\$($obj.key)" -Status "Working..."
						$regpath = $obj.Fixedkey
						$regpath = '"' + $regpath.replace('"', '\"') + '"' + ' /f'
						$obj.status = "Fixed"
						#Write-Output "Key to Fix: " $($obj.key)
						#Write-Output "Fixed Path" $regpath
						# Comment the next line out to run without modifying the registry
						# Alternatively uncomment any line with Write-Output or Write-Object for extra verbosity.
						REG ADD "$($obj.key)" /v ImagePath /t REG_EXPAND_SZ /d $regpath
					}
					#Write-Output $obj
					
					$obj = $nul #clear $obj
            	}	
            } #end top else
         
            $count = $count + 2
        } #End While
	} #End If	
