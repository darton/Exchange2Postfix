$action = New-ScheduledTaskAction -Execute 'Powershell.exe' `
  -Argument '-file "c:\export\pscp.ps1"'

$trigger =  New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minute 1) 

$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "SentToScript" -Description "Generate SentTo from TransportRule"
