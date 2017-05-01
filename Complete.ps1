$MDTDriveLetter = 'K'
$LocalWimStore = 'D:\ITMDT\'
$WimShareLocation = 'Operating Systems\GenLab\'
$WimName = 'install.wim'
$SharePass="Readonly2014"| ConvertTo-SecureString -AsPlainText -Force
$ShareCred = New-Object System.Management.Automation.PsCredential('MDT',$SharePass)
$WimMount = 'C:\Offline\'
$VHDLocation = 'D:\'
$VHDLetter = 'O'
$Volumes = @("Cisco","VSS")



if (test-path "$MDTDriveLetter`:\"){
    write-host "Removing drive $MDTDriveLetter`:\"
    Remove-PSDrive -Name $MDTDriveLetter | Out-Null
}

write-host "Mapping MDT share to $MDTDriveLetter`:\"
New-PSDrive –Name $MDTDriveLetter –PSProvider FileSystem –Root “\\mdt-server2012.conc.students.local\deploymentshare$” -Credential $ShareCred | Out-Null

if (!(test-path $LocalWimStore)){
    write-host "Creating $LocalWimStore"
    New-Item $LocalWimStore -type directory | Out-Null
}

if (!(test-path $LocalWimStore$WimName)){
    write-host "Copying $MDTDriveLetter`:\$WimShareLocation$WimName to $LocalWimStore"
    copy-item "$MDTDriveLetter`:\$WimShareLocation$WimName" $LocalWimStore | Out-Null


if (!(test-path $WimMount)){
    write-host "Creating $WimMount"
    New-Item $WimMount -type directory | Out-Null
}

write-host "Mounting wim on $WimMount"
Dism /Mount-Image /ImageFile:$LocalWimStore$WimName /index:1 /MountDir:$WimMount | Out-Null

write-host "Injecting current drivers into the wim"
get-windowsdriver -online | % {add-windowsdriver -Path $WimMount -Driver $_.OriginalFileName} | Out-Null

write-host "Unmounting and committing changes to the wim"
Dism /Unmount-Image /MountDir:$WimMount /Commit | Out-Null

write-host "Cleaning up"
Remove-Item -Path $WimMount -Force | Out-Null

}


#create multiple vhds here

$DriveProperties = Get-WmiObject Win32_logicaldisk | where {$_.DeviceID -eq "C:"}
$DriveSizeMB = $DriveProperties.Size / 1MB
$VHDSizeMB = $DriveSizeMB * 0.2
$VHDSizeMB = [math]::Round($VHDSizeMB)



foreach ($Volume in $Volumes){
$VHDName = "$Volume.vhd"

write-host "Create diskpart.txt Diskpart script provision new VHD"
New-Item -Name 'diskpart.txt' -Path 'C:\' -ItemType file -Force 
Add-Content –path C:\diskpart.txt “create vdisk file=$VHDLocation$VHDName maximum=$VHDSizeMB type=expandable”
Add-Content –path C:\diskpart.txt “attach vdisk"
Add-Content –path C:\diskpart.txt “create partition primary"
Add-Content –path C:\diskpart.txt “format fs=ntfs label=`"$Volume`" quick"
Add-Content –path C:\diskpart.txt “assign letter=$VHDLetter"
Add-Content –path C:\diskpart.txt “exit”

write-host "Running Diskpart"
diskpart /s C:\diskpart.txt

write-host "Remvoing diskpart.txt Diskpart script"
Remove-Item -Path 'C:\diskpart.txt' -Force

write-host "Applying Image $WimName to $VHDLetter`:\"
Dism /apply-image /imagefile:$LocalWimStore$WimName /index:1 /ApplyDir:"$VHDLetter`:\"

write-host "Making the VHD bootable"


$BootEntry = bcdedit /copy '{default}' /d $Volume
$GUID = ([Regex]::Matches($BootEntry, '(?<={)(.*?)(?=})')).Value

bcdedit /set "{$GUID}" device vhd=[locate]\$VHDName
bcdedit /set "{$GUID}" osdevice vhd=[locate]\$VHDName



$adminPass = ""

switch ($Volume){
    "Cisco" { $adminPass = "network" } 
    "VSS"   { $adminPass = "network" }

}

$unattendFile = "C:\Users\NHTI\Desktop\Unattend.xml"

$xml = [xml](Get-Content $unattendFile)

$specialize = $xml.unattend.settings | ? { $_.pass -eq 'specialize' }
$shellsetup = $specialize.component | ? { $_.name -eq 'Microsoft-Windows-Shell-Setup' }
$shellsetup.computername = "$env:computername-$Volume"

if ( $Volume -like "Server*" ) {
$join = $specialize.component | ? { $_.name -eq 'Microsoft-Windows-UnattendedJoin' }
$join.Identification.Credentials.Password = "VOID"
}

$oobeSystem = $xml.unattend.settings | ? { $_.pass -eq 'oobeSystem' }
$shellsetup = $oobeSystem.component | ? { $_.name -eq 'Microsoft-Windows-Shell-Setup' }
$shellsetup.UserAccounts.AdministratorPassword.Value = $adminPass
$shellsetup.AutoLogon.Username = "Administrator"
$shellsetup.AutoLogon.Password.Value = $adminPass

$xml.save("O:\Windows\System32\Sysprep\unattend.xml")



copy-item C:\Users\NHTI\Desktop\ITStartup.vbs O:\Windows\System32\Sysprep\

write-host "Create diskpart.txt Diskpart script provision new VHD"
New-Item -Name 'diskpart.txt' -Path 'C:\' -ItemType file -Force 
Add-Content –path C:\diskpart.txt “select vdisk file=$VHDLocation$VHDName”
Add-Content –path C:\diskpart.txt “detach vdisk"
Add-Content –path C:\diskpart.txt “exit”

write-host "Running Diskpart"
diskpart /s C:\diskpart.txt

write-host "Remvoing diskpart.txt Diskpart script"
Remove-Item -Path 'C:\diskpart.txt' -Force

}

write-host "Setting legacy boot menu"
bcdedit /set '{bootmgr}' displaybootmenu yes
bcdedit /timeout 7

bcdedit /export C:\BOOTBACKUP
bcdedit /displayorder '{current}' /remove

#Remove-Item -Path $LocalWimStore -Force -Confirm:$false

write-host "Done!"