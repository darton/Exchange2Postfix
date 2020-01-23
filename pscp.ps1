$Path = "c:\export\"
$ComputerName = $env:COMPUTERNAME.ToLower()
$pscp = "pscp.exe"
$PostfixPrivateKey = "smarthost.ppk"
$ConfigFile = "email_$ComputerName.txt"
$ConfigFileold = "email_$ComputerName.old"
$HashFile = "email_$ComputerName.hash"
$PostfixUrl = "user@smarthost.example.com:/home/user/"
$ADBase = "DC=EXAMPLE,DC=COM"
$ScpCopyCmd = '& $Path$pscp -i $Path$PostfixPrivateKey $ScpOptions $PostfixUrl'


if (!(Test-Path $Path$ConfigFile -PathType Leaf)){

    Out-File -FilePath $Path$ConfigFile
}
if (!(Test-Path $Path$HashFile -PathType Leaf)){

    Out-File -FilePath $Path$HashFile
}
if ((Test-Path $Path$ConfigFileold -PathType Leaf)){

    del $Path$ConfigFileold
}

move $Path$ConfigFile $Path$ConfigFileold

Out-File -FilePath $Path$ConfigFile



###Get data from AD

##Get ADUser TargetAddress
#$ADUserTargetAddress = Get-ADUser -Filter {(TargetAddress -like "*")} -SearchBase $ADBase -Properties TargetAddress | ft TargetAddress 

##Get ADUser ProxyAddresses
$ADUserProxyAddresses = Get-ADUser -Filter *  -Properties proxyaddresses |Select-Object -ExpandProperty proxyaddresses | Select-String "smtp" | Foreach-Object { [pscustomobject] @{ProxyAddresses = $_} }

##Get AD Contact TargetAddress
$ContactTargetAddress = Get-ADObject -Filter 'objectClass -eq "contact"' -Properties TargetAddress | Format-table TargetAddress  

##Get AD Contact ProxyAddresses
$ContactProxyAddresses = Get-ADObject -Filter 'objectClass -eq "contact"' -Properties proxyaddresses |Select-Object -ExpandProperty proxyaddresses | Foreach-Object { [pscustomobject] @{ProxyAddresses = $_} } 



### Get data from MS Exchange 
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;

##Get Get-AcceptedDomain
$AcceptedDomain = Get-AcceptedDomain |select -ExpandProperty DomainName | foreach {"DomainName:" +$_}

## Get TransportRule SentTo
#$TransportRuleSentTo = foreach ($a in Get-TransportRule |select -ExpandProperty SentTo) {Write-Output SMTP:$a}
$TransportRuleSentTo = Get-TransportRule |select -ExpandProperty SentTo |foreach {"SMTP:" +$_}

##Get Mailbox EmailAddress
# Create an object to hold the results
$addresses = @()

# Get every mailbox in the Exchange Organisation
$Mailboxes = Get-Mailbox -ResultSize Unlimited

# Recurse through the mailboxes
ForEach ($mbx in $Mailboxes) {

# Recurse through every address assigned to the mailbox
    Foreach ($address in $mbx.EmailAddresses) {

# If it starts with "SMTP:" then it's an email address. Record it
        if ($address.ToString().ToLower().StartsWith("smtp:")) {
            # This is an email address. Add it to the list
            $obj = "" | Select-Object EmailAddress
            $obj.EmailAddress = $address.ToString().SubString(5)
            $addresses += $obj
        }
    }
}

# Export the final object to a csv in the working directory

$MailboxEmailAddress = $addresses  | select -expandproperty EmailAddress| foreach {"smtp:" +$_} | Sort-Object  

Remove-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;



###Writing data to file

$ADUserProxyAddresses | Out-File -Encoding UTF8 $Path$ConfigFile
$ContactTargetAddress | Out-File -Encoding UTF8 -Append $Path$ConfigFile
$ContactProxyAddresses | Out-File -Encoding UTF8 -Append $Path$ConfigFile
$TransportRuleSentTo | Out-File -Encoding UTF8 -Append $Path$ConfigFile
#$MailboxEmailAddress | Out-File -Encoding UTF8 -Append $Path$ConfigFile
$AcceptedDomain | Out-File -Encoding UTF8 -Append $Path$ConfigFile


###Comparing two files and sending new file to smarthost when old and new file is not equal
$ConfigFileHash = $(Get-FileHash $Path$ConfigFile).Hash 
$ConfigFileoldHash = $(Get-FileHash $Path$ConfigFileold).Hash

Write-Output $ConfigFileHash | Out-File -Encoding UTF8 $Path$HashFile


if ($ConfigFileHash -ne $ConfigFileoldHash) {

	Write-Output "Files $ConfigFile and $ConfigFileold aren't equal"

	$ScpOptions = "-ls"
        $AAAA = Invoke-Expression $ScpCopyCmd | select-string $ConfigFile 
 
	if ([string]::IsNullOrWhitespace($AAAA)){
        
        $ScpOptions = "$Path$ConfigFile"
 		Invoke-Expression $ScpCopyCmd
		Start-Sleep -s 2
        $ScpOptions = "$Path$HashFile"
	        Invoke-Expression $ScpCopyCmd
	}
	else {
		Write-Output "File still exist on remote host"
                Out-File -FilePath $Path$ConfigFile   
	}
}

else {
	Write-Output "New file is the same as old"
}

