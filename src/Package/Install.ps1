will {
	$hklmMountPath = 'HKLM\' + $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'.Substring(6)	
    if (Test-Path $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE')
    {
        say ("Dismounting registry hive: {0}" -f $hklmMountPath)
        reg.exe UNLOAD $hklmMountPath
    }
    else
    {
    	say ("The registry hive does not require dismounting: {0}" -f $hklmMountPath)
    }
}

task default -depends Finalize

task Precheck {
	assert ($BuildEnv.themeColor) "The themeColor entry is empty or undefined."

    @(
        'Windows/System32/config/SOFTWARE'
    ) | ForEach-Object {
        $regPath = $BuildEnv.registryMountPoint."$_"
        assert (Test-Path $regPath) ("A required registry hive was not loaded: {0}" -f $regPath)
    }
}

task UnprotectPackage -depends Precheck -precondition { $BuildEnv.package.unprotect.Count -ne 0 } {
	$regPath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'
	$pkgRegPath = Join-Path $regPath -ChildPath 'Microsoft/Windows/CurrentVersion/Component Based Servicing/Packages'
	$allPackages = dir $pkgRegPath

	$BuildEnv.package.unprotect | ForEach-Object {
		$pkgWildcard = $_
		$targetPkgs = $allPackages | where { $_.PSChildName -like $pkgWildcard }

		if ($targetPkgs.Count -gt 0)
		{
			$targetPkgs | ForEach-Object {
				say ("Found package matching '{0}': {1}" -f $pkgWildcard, $_)

				$visibleCode = $_ | Get-ItemProperty -Name Visibility | select -expand Visibility
				if ($visibleCode -ne 1)
				{
					say ("Making package visible.")

					Grant-AdminFullRegistryKeyAccess -Path ('HKLM:\' + $_.PSPath.Substring('Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\'.Length))
					$_ | Set-ItemProperty -Name Visibility -Value 1
				}
				else
				{
					say ("Package is already visible.")
				}

				$ownersKey = Join-Path ('HKLM:\' + $_.PSPath.Substring('Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\'.Length)) -ChildPath 'Owners'
				if (Test-Path $ownersKey)
				{
					say ("Unprotecting package")

					Grant-AdminFullRegistryKeyAccess -Path $ownersKey
					del $ownersKey
				}
				else
				{
					say ("Package is already unprotected.")
				}
			}

            # Very important. You need to lose the handle or reg mountpoint cannnot be dismounted

			$targetPkgs | ForEach-Object {
				if ($_.Handle)
				{
					$_.Handle.Close()
				}
			}

			$targetPkgs | ForEach-Object {
				if ($_)
				{
					$_.Dispose()
				}
			}
		}
		else
		{
			say ("No package found that matches {0}" -f $pkgWildcard)
		}
	}

    # Again, just to be very safe.
    # GC collect to be certain!

	$allPackages | ForEach-Object {
		if ($_.Handle)
		{
			$_.Handle.Close()
		}
	}

	$allPackages | ForEach-Object {
		if ($_)
		{
			$_.Dispose()
		}
	}

	[gc]::Collect()
}

task DismountRegistry -depends UnprotectPackage -precondition { $BuildEnv.package.unprotect.Count -ne 0 } {
    # we need to dismount it or remove packages won't work

	$regFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows/System32/config/SOFTWARE'
	$regPath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'
	$hklmMountPath = 'HKLM\' + $regPath.Substring(6)
    say ("Dismounting registry hive: {0}" -f $hklmMountPath)
	exec { reg.exe UNLOAD $hklmMountPath }
}

task RemovePackage -depends DismountRegistry -precondition { $BuildEnv.package.remove.Count -ne 0 } {
	$mountPath = $BuildEnv.mountDir

	$allPackages = Get-WindowsPackage -Path $mountPath
	$BuildEnv.package.remove | ForEach-Object {
		$pkgWildcard = $_
		$targetPkg = $allPackages | where { $_.PackageName -like $pkgWildcard }
		if ($targetPkg)
		{
			$targetPkg | ForEach-Object {
				say ("Removing package '{0}': {1}" -f $pkgWildcard, $_.PackageName)
				Remove-WindowsPackage -Path $mountPath -PackageName $_.PackageName			
			}
		}
		else
		{
			say ("No package found that matches {0}" -f $pkgWildcard)
		}
	}
}

task Finalize -depends RemovePackage {
	say 'Done!'
}
