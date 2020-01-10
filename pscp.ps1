$Path = "c:\export\"
$pscp = "pscp.exe"
$PostfixPrivateKey = "smarthost.example.com.ppk"
$TargetAddressesFile = "e-mail.txt"
$TargetAddressesFileold = "e-mail_old.txt"
$HashFile = "e-mail.ok"
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

move $Path$TargetAddressesFile $Path$TargetAddressesFileold

Out-File -FilePath $Path$TargetAddressesFile

Get-ADUser -Filter {(TargetAddress -like "*")} -SearchBase $ADBase -Properties TargetAddress | ft TargetAddress | Out-File -Encoding UTF8 $Path$TargetAddressesFile

$TargetAddressesFileHash = $(Get-FileHash $Path$TargetAddressesFile).Hash 
$TargetAddressesFileoldHash = $(Get-FileHash $Path$TargetAddressesFileold).Hash

Write-Output $TargetAddressesFileHash | Out-File -Encoding UTF8 $Path$HashFile

if ($TargetAddressesFileHash -ne $TargetAddressesFileoldHash) {

	Write-Output "Files $TargetAddressesFile and $TargetAddressesFileold aren't equal"

	$ScpOptions = "-ls"
    $AAAA = iex $ScpCopyCmd | select-string $TargetAddressesFile 
 
	if ([string]::IsNullOrWhitespace($AAAA)){
        
        $ScpOptions = "$Path$TargetAddressesFile"
 		iex $ScpCopyCmd
		Start-Sleep -s 2
        $ScpOptions = "$Path$HashFile"
	    iex $ScpCopyCmd
	}
	else {
		Write-Output "File still exist on remote host"
        Out-File -FilePath $Path$TargetAddressesFile   
	}
}

else {
	Write-Output "New file is the same as old"
}
