task default -depends Finalize

task Precheck {
	assert ($BuildEnv.appx) "The appx entry is empty or undefined."
}

task RemoveAppx -depends Precheck -precondition { $BuildEnv.appx.remove.Count -ne 0 } {
	$mountPath = $BuildEnv.mountDir

	say "Getting a list of available packages..."
	$appx = Get-AppxProvisionedPackage -Path $mountPath
	$appxNames = $appx | select -expand DisplayName

	$BuildEnv.appx.remove | ForEach-Object {
		$targetName = $_
		$targetFound = $false
		$appx | where { $_.DisplayName -match $targetName } | ForEach-Object {
			$targetFound = $true
			say ("Removing package: {0}" -f $_.PackageName)
			Remove-AppxProvisionedPackage -Path $mountPath -PackageName $_.PackageName
		}
		
		if ($targetFound -eq $false)
		{
			say ("The APPX provisioned package '{0}' cannot be removed because it was not found." -f $targetName)
		}
	}
}

task Finalize -depends Precheck, RemoveAppx {
	$mountPath = $BuildEnv.mountDir

	say "The following APPX packages will be installed:"
	Get-AppxProvisionedPackage -Path $mountPath | ForEach-Object {
		say ('- {0}' -f $_.DisplayName)
	}

	say 'Done!'
}
