#Remove Windows 10 Apps
#Use Get-AppxPackage to find other package names (you only need the short name as wildcards are used)

#Array that stores all windows apps to be removed
$AppsToBeRemoved = @("3dbuilder","windowscommunicationsapps","windowscamera","officehub","skypeapp","getstarted","zune","windowsmap","solitairecollection","bingfinance","dvd","bingnews","onenote","people","windowsphone","bingsports","soundrecorder","xbox","sway","messaging","CommsPhone","candy","twitter","fresh","translator","eclips","duolingo","picsart","wunderlist","facbook","photoshop","advertising","connect","flipboard","feedback","MiracastView","Microsoft3DViewer")
#Array that stores all provisioned windows apps
$ProvisionedApps = @(Get-ProvisionedAppxPackage -Online)

#Loops through all Apps and stores each app in $App
foreach ($App in $AppsToBeRemoved) {
    #Gets the properties of $App and pipes it to Remove-AppxPackage (uninstalls the app)
	Get-AppxPackage -AllUsers *$App* | Remove-AppxPackage
    #Unpins app
    ((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ?{$_.Name -like $App}).Verbs() | ?{$_.Name.replace('&','') -match 'Von "Start" lösen|Unpin from Start'} | %{$_.DoIt()}
    #Loops through all provisioned apps
    foreach ($ProvisionedApp in $ProvisionedApps){
        #Checks if the removed app is provisioned
        if($ProvisionedApp.PackageName -like "*$App*"){
            #Removes the provisioning for the app
            Remove-AppxProvisionedPackage -Online -PackageName $ProvisionedApp.PackageName
        }
    }

}

#Array of Services to be stopped and disabled for lab PCs
$ServicesToBeStopped = @("diagtrack")

foreach ($Service in $ServicesToBeStopped) {

#Stop and disable service
stop-service $Service
set-service $Service -startuptype disabled
	
}
