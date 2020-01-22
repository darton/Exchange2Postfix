$Path = "c:\export\"
$pscp = "pscp.exe"
$PostfixPrivateKey = "smarthost.example.com.ppk"
$TargetAddressesFile = "email.txt"
$TargetAddressesFileold = "email.old"
$HashFile = "email.hash"
$PostfixUrl = "ex2k@smarthost.example.com:/home/ex2k/"
$ADBase = "DC=EXAMPLE,DC=COM"
$ScpCopyCmd = '& $Path$pscp -i $Path$PostfixPrivateKey $ScpOptions $PostfixUrl'

if (!(Test-Path $Path$TargetAddressesFile -PathType Leaf)){

    Out-File -FilePath $Path$TargetAddressesFile
}
if (!(Test-Path $Path$HashFile -PathType Leaf)){

    Out-File -FilePath $Path$HashFile
}
if ((Test-Path $Path$TargetAddressesFileold -PathType Leaf)){

    del $Path$TargetAddressesFileold
}

Move-Item $Path$TargetAddressesFile $Path$TargetAddressesFileold

Out-File -FilePath $Path$TargetAddressesFile

Get-ADUser -Filter {(TargetAddress -like "*")} -SearchBase $ADBase -Properties TargetAddress | ft TargetAddress | Out-File -Encoding UTF8 $Path$TargetAddressesFile
Get-ADObject -Filter 'objectClass -eq "contact"' -SearchBase $ADBase -Properties TargetAddress | ft TargetAddress  | Out-File -Encoding UTF8 -Append $Path$TargetAddressesFile

$TargetAddressesFileHash = $(Get-FileHash $Path$TargetAddressesFile).Hash 
$TargetAddressesFileoldHash = $(Get-FileHash $Path$TargetAddressesFileold).Hash

Write-Output $TargetAddressesFileHash | Out-File -Encoding UTF8 $Path$HashFile

if ($TargetAddressesFileHash -ne $TargetAddressesFileoldHash) {

	Write-Output "Files $TargetAddressesFile and $TargetAddressesFileold aren't equal"

	$ScpOptions = "-ls"
        $AAAA = Invoke-Expression $ScpCopyCmd | select-string $TargetAddressesFile 
 
	if ([string]::IsNullOrWhitespace($AAAA)){
        
        	$ScpOptions = "$Path$TargetAddressesFile"
 		Invoke-Expression $ScpCopyCmd
		Start-Sleep -s 2
        	$ScpOptions = "$Path$HashFile"
		Invoke-Expression $ScpCopyCmd
	
	}
	else {
		Write-Output "File still exist on remote host"
                Out-File -FilePath $Path$TargetAddressesFile   
	}
}

else {
	Write-Output "New file is the same as old"
}
