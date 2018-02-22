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
	assert ($BuildEnv.oemInfo) "The oemInfo entry is empty or undefined."

	@('helpLogo', 'pcLogo') | ForEach-Object {
		assert ($BuildEnv.oemInfo."$_" -ne '') "The oemInfo.$_ entry is empty or undefined."

        $defaultFilePath = Join-Path $BuildEnv.resDir -ChildPath $BuildEnv.oeminfo."$_"
        $fallbackFilePath = Join-Path $BuildEnv.BuildScriptDir -ChildPath $BuildEnv.oeminfo."$_"

        if (Test-Path $defaultFilePath -PathType Leaf)
        {
            $BuildEnv.oemInfo."$_" = $defaultFilePath
        }
        elseif (Test-Path $fallbackFilePath -PathType Leaf)
        {
            say "Using fallback image: {0}" -v 0
            $BuildEnv.oemInfo."$_" = $fallbackFilePath
        }
        else
        {
            assert $false ("Resource file not found: {0}" -f $_)
        }
	}
}

task MountRegistry -depends Precheck {
	$regFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows/System32/config/SOFTWARE'
	$regPath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'
	$hklmMountPath = 'HKLM\' + $regPath.Substring(6)

    say ("Mounting registry to hive: {0} --> {1}" -f $regFile, $hklmMountPath)
	reg.exe LOAD $hklmMountPath $regFile
}

task ModifyRegistry -depends MountRegistry {
    $regBasePath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE' + '\Microsoft\Windows\CurrentVersion\OEMInformation'

	If (-not (Test-Path $regBasePath))
	{
		md $regBasePath -Force | Out-Null
	}

    $oemProps = $BuildEnv.oemInfo | Get-Member -MemberType NoteProperty | select -expand Name
    $oemProps | where { $_ -notin @('Logo', 'HelpCustomized') } | ForEach-Object {
        say ("Set OEM: {0} = {1}" -f $_, $BuildEnv.oemInfo."$_")
	    Set-ItemProperty -Path $regBasePath -Name $_ -Value $BuildEnv.oemInfo."$_"
    }

    say ("Set OEM: Logo = %windir%\System32\oobe\Info\oemlogo-pc.bmp")
    Set-ItemProperty -Path $regBasePath -Name "Logo" -Value '%windir%\System32\oobe\Info\oemlogo-pc.bmp'

    if ($BuildEnv.oemInfo.helpCustomized -eq $true)
    {
        say ("Set OEM: HelpCustomized = true")
    	Set-ItemProperty -Path $regBasePath -Name "HelpCustomized" -Value 1
    }
    else
    {
        say ("Set OEM: HelpCustomized = false")
    	Set-ItemProperty -Path $regBasePath -Name "HelpCustomized" -Value 0
    }
}

task DismountRegistry -depends ModifyRegistry {
	$regFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows/System32/config/SOFTWARE'
	$regPath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'
	$hklmMountPath = 'HKLM\' + $regPath.Substring(6)
    say ("Dismounting registry hive: {0}" -f $hklmMountPath)
	reg.exe UNLOAD $hklmMountPath
}

task CopyFiles -depends DismountRegistry {
    $destFolder = Join-Path $BuildEnv.mountDir -ChildPath 'Windows\System32\oobe\Info'
    if (-not (Test-Path $destFolder))
    {
        md $destFolder | Out-Null
    }

    $srcPath = $BuildEnv.oemInfo.pcLogo
    say ("Copy file {0} --> {1}" -f $srcPath, "$destFolder\oemlogo-pc.bmp")
    copy $srcPath "$destFolder\oemlogo-pc.bmp"

    $srcPath = $BuildEnv.oemInfo.helpLogo
    say ("Copy file {0} --> {1}" -f $srcPath, "$destFolder\")
    copy $srcPath "$destFolder\"
}

task Finalize -depends Precheck, CopyFiles {
	say 'Done!'
}
