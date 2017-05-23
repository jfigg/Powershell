$script:loglocation = "C:\users\nhti\desktop\test.log"
function write-log
{
	param ($message)
	#Write to the screen the state
	write-host $message
	#Store date
	$date = get-date -format G
	#Format message
	$message = "{0}{1}: {2}" -f ('-' * 30), $date, $message.ToUpper()
	$message = $message.PadRight(100, '-')
	#Write out to log
	$message 2>&1 | Out-File -Append $loglocation
}



$success = 0
$installdf = 1
$checkthawstate = 2
$windowscleanup = 3
$finalizehost = 4
$createvolumes = 5
$rebootfrozen = 6

$drivename = (Get-PSDrive $env:SystemDrive.Substring(0, 1)).description

while ($true)
{
	try
	{
		$currentregvalue = Get-ItemPropertyValue "HKLM:\SOFTWARE\NHTI" "PostDeployInProgress"
	}
	catch
	{
		write-log "PostDeployInProgress does not exist"
		exit
	}
	switch ($currentregvalue)
	{
		$success {
			exit
		}
		$installdf {
			
			$dfexe = test-path "$env:systemdrive\DF\DFWKs.exe"
			if ($dfexe)
			{
				write-log "Installing Deepfreeze"
				Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $checkthawstate
				& "$env:systemdrive\DF\DFWKs.exe" "/install" 2>&1 | Out-File -Append $loglocation
			}
			else
			{
				write-log "Deepfreeze executable does not exist"
			}
			exit
		}
		$checkthawstate {
			$dfstatus = (get-itemproperty "HKLM:\SOFTWARE\WOW6432Node\Faronics\Deep Freeze 6\")."DF Status".toupper()
			
			write-log "Checking thaw state"
			
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $windowscleanup
			
			if ($dfstatus -eq "FROZEN")
			{
				$number = $env:COMPUTERNAME.substring($env:COMPUTERNAME.length - 2, 2)
				
				if ($number -eq '00')
				{
					write-log "Rebooting Thawed"
					$bootType = "/BOOTTHAWED"
				}
				else
				{
					write-log "Rebooting Thawed and Locked"
					$bootType = "/BOOTTHAWEDNOINPUT"
				}
				
				& "$env:systemdrive\Windows\SysWOW64\DFC.exe" "kiwi" "$bootType" 2>&1 | Out-File -Append $loglocation
			}
			
		}
		$windowscleanup {
			
			#Remove Windows 10 Apps
			#Use Get-AppxPackage to find other package names (you only need the short name as wildcards are used)
			
			#Array that stores all windows apps to be removed
			$AppsToBeRemoved = @("3dbuilder", "windowscommunicationsapps", "windowscamera", "officehub", "skypeapp", "getstarted", "zune", "windowsmap", "solitairecollection", "bingfinance", "dvd", "bingnews", "onenote", "people", "windowsphone", "bingsports", "soundrecorder", "xboxapp", "sway", "messaging", "CommsPhone", "candy", "twitter", "fresh", "translator", "eclips", "duolingo", "picsart", "wunderlist", "facbook", "photoshop", "advertising", "connect", "flipboard", "feedback")
			#Array that stores all provisioned windows apps
			$ProvisionedApps = @(Get-ProvisionedAppxPackage -Online)
			
			write-log "Removing apps"
			#Loops through all Apps and stores each app in $App
			foreach ($App in $AppsToBeRemoved)
			{
				#Gets the properties of $App and pipes it to Remove-AppxPackage (uninstalls the app)
				Get-AppxPackage -AllUsers *$App* | Remove-AppxPackage 2>&1 | Out-File -Append $loglocation
				#Unpins app
				((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ?{ $_.Name -like $App }).Verbs() | ?{ $_.Name.replace('&', '') -match 'Von "Start" lösen|Unpin from Start' } | %{ $_.DoIt() } 2>&1 | Out-File -Append $loglocation
				#Loops through all provisioned apps
				foreach ($ProvisionedApp in $ProvisionedApps)
				{
					#Checks if the removed app is provisioned
					if ($ProvisionedApp.PackageName -like "*$App*")
					{
						#Removes the provisioning for the app
						Remove-AppxProvisionedPackage -Online -PackageName $ProvisionedApp.PackageName 2>&1 | Out-File -Append $loglocation
					} #end if
				} #end for each provisioned app
				
			} #end for each app
			
			write-log "Stopping and disabling services"
			#Array of Services to be stopped and disabled for lab PCs
			$ServicesToBeStopped = @("diagtrack")
			
			foreach ($Service in $ServicesToBeStopped)
			{
				
				#Stop and disable service
				stop-service $Service 2>&1 | Out-File -Append $loglocation
				set-service $Service -startuptype disabled 2>&1 | Out-File -Append $loglocation
				
			} #end for each
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $finalizehost
		}
		$finalizehost {
			write-log "Finalizing host"
			
			#Open Start Menu
			[System.Windows.Forms.SendKeys]::SendWait("^{ESC}")
			Start-sleep -Seconds 5
			[System.Windows.Forms.SendKeys]::SendWait("^{ESC}")
			
			#Fix Wallpaper
			write-log "Fix Wallpaper"
			cmd.exe /C "RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True" 2>&1 | Out-File -Append $loglocation
			
			#Enable Remote Desktop Firewall Rule
			write-log "Enable Remote Desktop Firewall Rule"
			netsh advfirewall firewall set rule group='Remote Desktop' new enable=yes 2>&1 | Out-File -Append $loglocation
			
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $createvolumes
		}
		$createvolumes {
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $rebootfrozen
			write-log "Creating volumes"
			shutdown /r /t 10
			exit
		}
		$rebootfrozen {
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $success
			write-log "Rebooting frozen"
			& "$env:systemdrive\Windows\SysWOW64\DFC.exe" "kiwi" "/FREEZENEXTBOOT" 2>&1 | Out-File -Append $loglocation
			shutdown /r /t 10
			write-log "Delete self"
			#delete self
			exit
		}
		
		
	} #end switch
} #end while