 
$pathCSV = "C:\Users\jfigg.NHTI\Documents\admin.csv"

$serverList= Get-Content $pathCSV -ErrorAction Stop

$onlineServers = [System.Collections.ArrayList]@()

$ServersExport = @("Server Name")

$DNSExport = @("Primary DNS Server")

$exportlist = @()

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
        $ipconfig = invoke-command -computername $server -ErrorAction Stop -ScriptBlock { ipconfig /all }

        $dnsserver = $ipconfig | select-string "DNS Server" | select-object -First 1 

        $dnsserver = $dnsserver -split ": ", 0 | select-object -Index 1  

        write-host "Server: $server, DNSServer: $dnsserver"
        $ServersExport += $server
        $DNSExport += $dnsserver
        
    }
    Catch {
        $ServersExport += $server
        $DNSExport += "Failed to retrieve"
        write-host -fore Red "$server failed to retrieve"
        continue
    }
}

0..($ServersExport.Count - 1) | ForEach-Object {$exportlist += @("$($ServersExport[$_]), $($DNSExport[$_])")}


$exportlist | Set-Content "C:\Users\jfigg.NHTI\Documents\DNSServerIPs-06-12-2017.csv"