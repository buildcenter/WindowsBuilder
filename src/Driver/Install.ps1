task default -depends Finalize

task Precheck {
	assert ($BuildEnv.driver) "The 'driver' entry is empty or undefined."
	assert (($BuildEnv.driver.path -ne '') -and ($BuildEnv.driver.path -is [string])) "The 'driver.path' entry is empty or undefined."
}}

task AddDrivers -depends Precheck {
	$mountPath = $BuildEnv.mountDir

	if (-not (Test-Path $BuildEnv.driver.path -PathType Container))
	{
		say ("The driver resource folder does not exist: {0}" -f $BuildEnv.driver.path)
		return
	}

	$addWindowsDriverParams = @{
		Recurse = $true
		Path = $BuildEnv.driver.path
	}
	
	if ($BuildEnv.driver.unsigned -eq $true)
	{
		$addWindowsDriverParams.ForceUnsigned = $true
	}

	Add-WindowsDriver @addWindowsDriverParams
}

task Finalize -depends Precheck, AddDrivers {
	$mountPath = $BuildEnv.mountDir

	say "The following drivers will be installed:"
	Get-WindowsDriver -Path $mountPath

	say 'Done!'
}
