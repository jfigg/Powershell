$success = 0
$installdf = 1
$checkthawstate = 2
$windowscleanup = 3
$finalizehost = 4
$createvolumes = 5
$rebootfrozen = 6

$textfilelocation = "C:\Users\NHTI\Desktop"


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
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $checkthawstate
			Out-File $textfilelocation\InstallDF.txt
			shutdown /r /t 10
			exit
		}
		$checkthawstate {
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $windowscleanup
			Out-File $textfilelocation\CheckThawState.txt
			shutdown /r /t 10
			exit
		}
		$windowscleanup {
			Set-ItemProperty -path "HKLM:\SOFTWARE\NHTI" -name "PostDeployInProgress" -value $finalizehost
			Out-File $textfilelocation\WindowsCleanup.txt
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