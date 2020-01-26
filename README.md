## pscp.ps1

The script can be installed in the c: \ export directory, e.g. on MS Exchange Server or if we use Exchange DAG, e.g. on the Witness instance.
The script can be run by the system, e.g. every minute.

The pscp.ps1 script retrieves data from AD. Then it creates 2 files:
one with email addresses and the other with the first file's hash. 
Then sends them to Smarthost running under Linux using pscp software.

The files is sent only if there has been any change in the generated data.

To avoid overwriting the file during data processing by Smarthost software, the script checks if the file previously sent to Smarhost exists. The new file is not sent until the file previously sent to Smarthost has been deleted.

To avoid Smarthost's processing of a file that has not been fully uploaded, the script sends an additional $HashFile file, whose presence is for software running on Smarthost's side that the $TargetAddressesFile file has been sent in full.
$Hashfile is also used to verify the checksum of the Hashfile is also used to verify the checksum of the $TargetAddressesFile.


## postfix_map.sh

Script postfix_map.sh working on linux based Smarthost. This script creates a relay_recipients file for postfix.
The script can be run by the system, e.g. every minute.


## blacklist

A file in which to put a list of domains or email addresses that are not to appear in the file created by postfix_map.sh.
