$success = 0
$installdf = 1
$checkthawstate = 2
$windowscleanup = 3
$finalizehost = 4
$createvolumes = 5
$rebootfrozen = 6


write-host "read reg key to $regkey"

while ($true) {

switch ($regkey) {
    $success {
        writ-host "exit"
    }
    $installdf {
        write-host "check df installer location does not exist"
            write-host "write to log: no df"
            write-host "exit"
        write-host "set $regkey to $checkthawstate"
        write-host "write to log: install df"
        write-host "install df"
        write-host "exit"
    }
    $checkthawstate {
        write-host "check status of df"
            write-host "if frozen:" 
                write-host "reboot thawed and locked unless 00 then thawed"
            write-host "if -like thawed*:"
                write-host "write to log: system thawed"
                write-host "run launch apps foreach (read from data.xml)"
                write-host "set $regkey to $windowscleanup"
    }
    $windowscleanup {
        write-host "run windows cleanup"
        write-host "write to log: ran windows cleanup"
        write-host "set $regkey to $finalizehost"
    }
    $finalizehost {
        write-host "if dental or mosaiq:"
            write-host "remove dental and mosaiq autologin"
            write-host "write to log: removed autologin for dental and mosaiq"
            write-host "if dental:"
                write-host "add reg keys from data.xml"
                write-host "write to log: added dentrix reg keys"
            write-host "defragment drive"
            write-host "write to log: defragmented drive"
            write-host "set $regkey to $createvolumes"

    }
    $createvolumes {
        write-host "if IT or IT-FARNUM:"
            write-host "we are IT"
        write-host "set $regkey to $rebootfrozen"
    }
    $rebootfrozen {
        write-host "set $regkey to $success"
        write-host "if NOT computername like *00:"
            write-host "C:\Windows\SysWOW64\DFC.exe kiwi /FREEZENEXTBOOT"
        write-host "reboot in 30 seconds"
        write-host "delete mdt folder"
        write-host "delete self"
    }

    
}#end switch
write-host "read reg key to $regkey"
}#end wh