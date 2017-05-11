$script:loglocation = "C:\Windows\CCM\Logs\PostDeploy.log"
function write-log {
    param ($message)
    #Write to the screen the state
    write-host $message
    #Store date
    $date = get-date -format G
    #Format message
    $message = "{0}{1}: {2}" -f ('-' * 30),$date,$message.ToUpper()
    $message = $message.PadRight(100,'-')
    #Write out to log
    $message | Out-File -Append $loglocation
}



write-log "Installing Deepfreeze"
Get-ChildItem C:\Users\NHTI\Desktop -Recurse | Out-File -Append $loglocation
write-log "Deepfreeze Installed"