 
$pathCSV = "C:\Users\jfigg\Documents\admin.csv"

$serverList= Get-Content $pathCSV -ErrorAction Stop

$onlineServers = [System.Collections.ArrayList]@()

$updates = @()

 foreach($server in $serverList)
 {
    write-host -fore DarkGreen "Pinging $server"

    #ping code
    if (Test-Connection -ComputerName $server -Count 1 -ErrorAction SilentlyContinue){
        write-host -fore Green $server " is responding"
        $temp = $onlineServers.Add($server)
    }
    else{
        write-host -fore Red $server " is offline"
        $updates += "$server is offline"
    }

}



foreach ($server in $onlineServers){
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
}


$updates | format-table PSComputerName,Description,HotFixID,InstalledOn,OSName | Out-File "C:\Users\jfigg.NHTI\Documents\ServerUpdateStatus.txt"
