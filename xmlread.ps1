 [xml]$XmlDocument = Get-Content -Path C:\users\nhti\desktop\test.xml
#$XmlDocument | select ChildNodes | % { write-host $_.applications }

#$XmlDocument.postdeploydata.regkeys.delete | % { write-host $_ }
$XmlDocument.postdeploydata.regkeys.delete | % { reg delete "$_" }