$Path = "C:\export\files\"
$PostfixUrl = "user@smarthost.example.com:/home/user/"

$PscpPath = "C:\export\"
$pscp = "pscp.exe"
$PostfixPrivateKey = "user.ppk"
$ScpCopyCmd = '& $PscpPath$pscp -i $PscpPath$PostfixPrivateKey $ScpOptions $PostfixUrl'

$ComputerName = $env:COMPUTERNAME.ToLower()
$EmailFile = "email_$ComputerName.txt"
$EmailFileold = "email_$ComputerName.old"
$EmailHashFile = "email_$ComputerName.hash"

$lockfile = “c:\export\lock.lck"

$lockstatus = 0

While ($lockstatus -ne 1)
    {
        If (Test-Path $lockfile)
    {

echo “Lock file found!”

$pidlist = Get-content $lockfile

If (!$pidlist)
    {
        $PID | Out-File $lockfile
        $lockstatus = 1
    }

$currentproclist = Get-Process | ? { $_.id -match $pidlist }

If ($currentproclist)
{
        echo “lockfile in use by other process!”
        $rndwait = New-Object system.Random
        $rndwait= $rndwait.next(1,4)
        echo “Sleeping for $rndwait seconds”
        Start-Sleep $rndwait
    }
Else
    {
    Remove-Item $lockfile -Force
    $PID | Out-File $lockfile
    $lockstatus = 1
    }
}
Else
{
    $PID | Out-File $lockfile
    $lockstatus = 1
}
}

## Main Script Part
## ----------------

if (!(Test-Path $Path$EmailFile -PathType Leaf)){

    Out-File -FilePath $Path$EmailFile
}
if (!(Test-Path $Path$EmailHashFile -PathType Leaf)){

    Out-File -FilePath $Path$EmailHashFile
}
if ((Test-Path $Path$EmailFileold -PathType Leaf)){

    del $Path$EmailFileold
}

move $Path$EmailFile $Path$EmailFileold

Out-File -FilePath $Path$EmailFile

### Get data from MS Exchange and export recipients to csv
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;

$addresses = @()
$recipients = Get-Recipient -ResultSize Unlimited
foreach ($read in $recipients){$addresses += $read.EmailAddresses.SmtpAddress; $addresses += $read.ExternalEmailAddress.SmtpAddress}
$addresses | sort -uniq | select {($_).tolower()} | Export-Csv $Path$EmailFile

Remove-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;

###Comparing two files and sending new file to smarthost when old and new file is not equal

$EmailFileHash = $(Get-FileHash $Path$EmailFile).Hash 
$EmailFileoldHash = $(Get-FileHash $Path$EmailFileold).Hash

Write-Output $EmailFileHash | Out-File -Encoding UTF8 $Path$EmailHashFile

if ($EmailFileHash -ne $EmailFileoldHash) {

	Write-Output "Files $EmailFile and $EmailFileold aren't equal"
        Start-Sleep -s 2
	$ScpOptions = "-ls"
        $AAAA = Invoke-Expression $ScpCopyCmd | select-string $EmailFile 
 
	if ([string]::IsNullOrWhitespace($AAAA)){
        
        $ScpOptions = "$Path$EmailFile"
 		    Invoke-Expression $ScpCopyCmd
		    Start-Sleep -s 2
        $ScpOptions = "$Path$EmailHashFile"
	        Invoke-Expression $ScpCopyCmd
	}
	else {
		Write-Output "File still exist on remote host"
                Out-File -FilePath $Path$EmailFile
	}
}

else {
	Write-Output "New file is the same as old"
        Start-Sleep -s 2
}

## -----------------
#remove the lockfile

Remove-Item $lockfile –Force
