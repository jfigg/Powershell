$script:loglocation = "$env:systemroot\CCM\Logs"
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
	$message | Out-File -Append $loglocation
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
	
	$currentregvalue = Get-ItemPropertyValue "HKLM:\SOFTWARE\NHTI" "PostDeployInProgress"
	
	switch ($currentregvalue)
	{
		$success {
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $success
			Out-File $textfilelocation\Success.txt
			exit
		}
		$installdf {
			
			$dfexe = test-path "$env:systemdrive\DF\DFWKs.exe"
			if ($dfexe)
			{
				write-log "Installing Deepfreeze"
				Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $checkthawstate
				$env:systemdrive\DF\DFWKs.exe | Out-File -Append $loglocation
			}
			else
			{
				write-log "Deepfreeze executable does not exist"
			}
			exit
		}
		$checkthawstate {
			$dfstatus = (get-itemproperty "HKLM:\SOFTWARE\WOW6432Node\Faronics\Deep Freeze 6\")."DF Status".toupper()
			
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
				
				C:\Windows\SysWOW64\DFC.exe kiwi $bootType | Out-File -Append $loglocation
			}
		exit
		}
		$windowscleanup {
			#Open Start Menu
			[System.Windows.Forms.SendKeys]::SendWait("^{ESC}")
			Start-sleep -Seconds 5
			[System.Windows.Forms.SendKeys]::SendWait("^{ESC}")
			
			#Fix Wallpaper
			write-log "Fix Wallpaper"
			cmd.exe /C "RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True" | Out-File -Append $loglocation
			
			#Enable Remote Desktop Firewall Rule
			write-log "Enable Remote Desktop Firewall Rule"
			netsh advfirewall firewall set rule group='Remote Desktop' new enable=yes | Out-File -Append $loglocation
			
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $finalizehost
		}
		$finalizehost {
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $createvolumes
			Out-File $textfilelocation\FinalizeHost.txt
			shutdown /r /t 10
			exit
		}
		$createvolumes {
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $rebootfrozen
			Out-File $textfilelocation\CreateVolumes.txt
			shutdown /r /t 10
			exit
		}
		$rebootfrozen {
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $success
			Out-File $textfilelocation\RebootFrozen.txt
			shutdown /r /t 10
			exit
		}
		
		
	} #end switch
} #end while