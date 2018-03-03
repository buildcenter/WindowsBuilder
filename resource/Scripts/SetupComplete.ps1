$logTimestampFormat = 'yyyy-MM-dd@hh:mm:ss'
$logPath = 'C:\Windows\oemsetup.log'

('[{0}] Starting OEM setup' -f (Get-Date -Format $logTimestampFormat)) | Add-Content -Path $logPath

('[{0}] Attempting to locate oem customization answer file' -f (Get-Date -Format $logTimestampFormat)) | Add-Content -Path $logPath
$oemDataFile = Join-Path $PSScriptRoot -ChildPath 'oemcustom.json'
if (Test-Path $oemDataFile -PathType Leaf)
{
	('[{0}] Answer file found. Reading...' -f (Get-Date -Format $logTimestampFormat)) | Add-Content -Path $logPath
	$oemdata = ConvertFrom-Json ((Get-Content -Path $oemDataFile) -join [Environment]::NewLine)
}
else
{
	('[{0}] OEM customization answer file was not found. Exiting.' -f (Get-Date -Format $logTimestampFormat)) | Add-Content -Path $logPath
	exit
}

if ($oemdata.computerDescription -and ($oemdata.computerDescription -is [string]))
{
	('[{0}] Setting computer description' -f (Get-Date -Format $logTimestampFormat)) | Add-Content -Path $logPath
	$oswmi = Get-WmiObject -Class Win32_OperatingSystem
	$oswmi.Description = $oemdata.computerDescription
	$oswmi.Put()
}

if ($oemdata.disableRemoteAssist -eq $true)
{
	('[{0}] Disable remote assistance' -f (Get-Date -Format $logTimestampFormat)) | Add-Content -Path $logPath
	Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Remote Assistance' -Name fAllowToGetHelp -Value 0
}

if ($oemdata.firewall -is [psobject])
{
	if ($oemdata.firewall.enable -is [array])
	{
		$oemdata.firewall.enable | ForEach-Object {
			if (($_ -is [string]) -and ($_ -ne ''))
			{
				Get-NetFirewallRule -Name $_ | ForEach-Object {
					if ($_.Enabled -eq 'False')
					{
						('[{0}] Enabling firewall rule: {1}' -f (Get-Date -Format $logTimestampFormat), $_.Name) | Add-Content -Path $logPath
						$_ | Set-NetFirewallRule -Enabled True
					}
				}
			}
		}
	}
	if ($oemdata.firewall.disable -is [array])
	{
		$oemdata.firewall.disable | ForEach-Object {
			if (($_ -is [string]) -and ($_ -ne ''))
			{
				Get-NetFirewallRule -Name $_ | ForEach-Object {
					if ($_.Enabled -eq 'True')
					{
						('[{0}] Disabling firewall rule: {1}' -f (Get-Date -Format $logTimestampFormat), $_.Name) | Add-Content -Path $logPath
						$_ | Set-NetFirewallRule -Enabled False
					}
				}
			}
		}
	}
}

if ($oemdata.kmsActivationServer -is [string])
{
	$kmsServerPort = '1688'

	if ($oemdata.kmsActivationServer.Contains(':'))
	{
		$kmsServerName = $oemdata.kmsActivationServer.Split(':')[0]
		$kmsServerPort = $oemdata.kmsActivationServer.Substring($kmsServerName.Length)

		if ($kmsServerPort.Length -gt 1)
		{
			$kmsServerPort = $kmsServerPort.Substring(2)
		}
		else
		{
			$kmsServerPort  = '1688'
		}
	}
	else
	{
		$kmsServerName = $oemdata.kmsActivationServer
	}

	('[{0}] Setting Windows KMS activation server to {1}:{2}' -f (Get-Date -Format $logTimestampFormat), $kmsServerName, $kmsServerPort) | Add-Content -Path $logPath

	Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform' -Name KeyManagementServiceName -Value $kmsServerName
	Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform' -Name KeyManagementServicePort -Value $kmsServerPort
}

if ($oemdata.windowsProductKey -is [string])
{
	('[{0}] Installing Windows product key.' -f (Get-Date -Format $logTimestampFormat)) | Add-Content -Path $logPath

	$licenceService = Get-WmiObject -Query "select * from SoftwareLicensingService"
	$licenceService.InstallProductKey($oemdata.windowsProductKey)
}

('[{0}] All done.' -f (Get-Date -Format $logTimestampFormat)) | Add-Content -Path $logPath
