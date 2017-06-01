 

$updates = @()
$server = "localhost"


    write-host -fore DarkGreen "Checking $server"
    Try {
        $osname = (Get-WmiObject -computername "$server" Win32_OperatingSystem).Name
        $osname = $osname.Substring(0, $osname.IndexOf('|'))
        $current = (get-hotfix -ComputerName "$server" -ErrorAction stop | sort installedon)[-1] 
        $current | Add-Member -type NoteProperty -Name 'OSName' -Value "$osname"
        $updates += $current
        write-host -fore Green "$server Checked"
    }
    Catch {
        $updates += "$server failed to retrieve"
        write-host -fore Red "$server failed to retrieve"
        continue
    }



$updates | format-table PSComputerName,Description,HotFixID,InstalledOn,OSName 
