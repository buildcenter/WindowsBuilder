task default -depends Finalize

task Precheck {
	assert ($BuildEnv.optionalFeatures) "The 'optionalFeatures' section is undefined."
}

task EnableOptionalFeature -depends Precheck -precondition { $BuildEnv.optionalFeatures.enable.Count -ne 0 } {
	$mountPath = $BuildEnv.mountDir

	$featDisabled = Get-WindowsOptionalFeature -Path $mountPath | where { $_.State -eq 'Disabled' }
	$featNames = $featDisabled | select -expand FeatureName

	$BuildEnv.optionalFeatures.enable | ForEach-Object {
		$targetName = $_
		$targetFound = $false

		$featDisabled | where { $_.FeatureName -eq $targetName } | ForEach-Object {
			say ("Enabling feature: {0}" -f $_.FeatureName)
			Enable-WindowsOptionalFeature -Path $mountPath -FeatureName $_.FeatureName
			$targetFound = $true
		}
		
		if ($targetFound -eq $false)
		{
			say ("The optional feature '{0}' is unavailable or may already be enabled." -f $targetName)
		}
	}
}

task DisableOptionalFeature -depends Precheck -precondition { $BuildEnv.optionalFeatures.disable.Count -ne 0 } {
	$mountPath = $BuildEnv.mountDir

	$featEnabled = Get-WindowsOptionalFeature -Path $mountPath | where { $_.State -eq 'Enabled' }
	$featNames = $featEnabled | select -expand FeatureName

	$BuildEnv.optionalFeatures.disable | ForEach-Object {
		$targetName = $_
		$targetFound = $false

		$featEnabled | where { $_.FeatureName -eq $targetName } | ForEach-Object {
			say ("Disabling feature: {0}" -f $_.FeatureName)
			Disable-WindowsOptionalFeature -Path $mountPath -FeatureName $_.FeatureName
			$targetFound = $true
		}
		
		if ($targetFound -eq $false)
		{
			say ("The optional feature '{0}' is unavailable or may already be disabled." -f $targetName)
		}
	}
}

task RemoveOptionalFeature -depends Precheck -precondition { $BuildEnv.optionalFeatures.remove.Count -ne 0 } {
	$mountPath = $BuildEnv.mountDir

	$allFeats = Get-WindowsOptionalFeature -Path $mountPath
	$featNames = $allFeats | select -expand FeatureName

	$BuildEnv.optionalFeatures.remove | ForEach-Object {
		$targetName = $_
		$targetFound = $false

		$allFeats | where { $_.FeatureName -eq $targetName } | ForEach-Object {
			say ("Uninstalling feature: {0}" -f $_.FeatureName)
			Disable-WindowsOptionalFeature -Path $mountPath -FeatureName $_.FeatureName -Remove
			$targetFound = $true
		}
		
		if ($targetFound -eq $false)
		{
			say ("The optional feature '{0}' is unavailable or may already be uninstalled." -f $targetName)
		}
	}
}

task Finalize -depends Precheck, RemoveOptionalFeature, DisableOptionalFeature, EnableOptionalFeature {
	$mountPath = $BuildEnv.mountDir

	say "The following Windows features will be enabled:"
	Get-WindowsOptionalFeature -Path $mountPath | where { $_.State -eq 'Enabled' } | ForEach-Object {
		say ('- {0}' -f $_.FeatureName)
	}

	say "The following Windows features will be disabled:"
	Get-WindowsOptionalFeature -Path $mountPath | where { $_.State -eq 'Disabled' } | ForEach-Object {
		say ('- {0}' -f $_.FeatureName)	
	}

	say 'Done!'
}
