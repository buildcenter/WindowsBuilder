task default -depends Finalize

task Precheck {
	assert ($BuildEnv.capability) "The windows capability entry is empty or undefined."
}

task RemoveCapability -depends Precheck -precondition { $BuildEnv.capability.remove.Count -ne 0 } {
	$mountPath = $BuildEnv.mountDir
	say "Getting a list of available capability..."
	$winCap = Get-WindowsCapability -Path $mountPath

	$BuildEnv.capability.remove | ForEach-Object {
		$targetName = $_
		$targetFound = $false
		$winCap | where { 
			($_.Name -like $targetName) -and 
			($_.State -eq 'Installed') 
		} | ForEach-Object {
			$targetFound = $true
			say ("Removing capability: {0}" -f $_.Name)
			Remove-WindowsCapability -Path $mountPath -Name $_.Name
		}
		
		if ($targetFound -eq $false)
		{
			say ("The Windows capability '{0}' cannot be removed because it was not found." -f $targetName)
		}
	}
}

task Finalize -depends Precheck, RemoveCapability {
	$mountPath = $BuildEnv.mountDir

	say "The following Windows capabilities will be installed:"
	Get-WindowsCapability -Path $mountPath | ForEach-Object {
		say ('- {0}' -f $_.Name)
	}

	say 'Done!'
}
