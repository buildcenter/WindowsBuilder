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

    $hkduMountPoint = 'HKLM\' + $BuildEnv.registryMountPoint.'Windows/System32/config/DEFAULT'.Substring(6)
    if (Test-Path $BuildEnv.registryMountPoint.'Windows/System32/config/DEFAULT')
    {
        say ("Dismounting registry hive: {0}" -f $hkduMountPoint)
        reg.exe UNLOAD $hkduMountPoint
    }
    else
    {
        say ("The registry hive does not require dismounting: {0}" -f $hkduMountPoint)
    }

    $hkuMountPoint = 'HKLM\' + $BuildEnv.registryMountPoint.'Users/Default/NTUSER.DAT'.Substring(6)
    if (Test-Path $BuildEnv.registryMountPoint.'Users/Default/NTUSER.DAT')
    {
        say ("Dismounting registry hive: {0}" -f $hkuMountPoint)
        reg.exe UNLOAD $hkuMountPoint
    }
    else
    {
        say ("The registry hive does not require dismounting: {0}" -f $hkuMountPoint)
    }
}

task default -depends Finalize

task Precheck {
	assert ($BuildEnv.cursors) "The cursors entry is empty or undefined."
}

task MountRegistry -depends Precheck {
	$regFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows/System32/config/SOFTWARE'
	$regPath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'
	$hklmMountPath = 'HKLM\' + $regPath.Substring(6)

    say ("Mounting registry to hive: {0} --> {1}" -f $regFile, $hklmMountPath)
	reg.exe LOAD $hklmMountPath $regFile


    $regFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows/System32/config/DEFAULT'
    $regPath = $BuildEnv.registryMountPoint.'Windows/System32/config/DEFAULT'
    $hkduMountPath = 'HKLM\' + $regPath.Substring(6)

    say ("Mounting registry to hive: {0} --> {1}" -f $regFile, $hkduMountPath)
    reg.exe LOAD $hkduMountPath $regFile


    $regFile = Join-Path $BuildEnv.mountDir -ChildPath 'Users/Default/NTUSER.DAT'
    $regPath = $BuildEnv.registryMountPoint.'Users/Default/NTUSER.DAT'
    $hkuMountPath = 'HKLM\' + $regPath.Substring(6)

    say ("Mounting registry to hive: {0} --> {1}" -f $regFile, $hkuMountPath)
    reg.exe LOAD $hkuMountPath $regFile
}

task ModifyRegistry -depends MountRegistry {
    $schemeBasePath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE' + '\Microsoft\Windows\CurrentVersion\Control Panel\Cursors\Schemes'
    $defaultBasePath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE' + '\Microsoft\Windows\CurrentVersion\Control Panel\Cursors\Default'
    $userCursorPath = $BuildEnv.registryMountPoint.'Windows/System32/config/DEFAULT' + '\Control Panel\Cursors'
    $defaultUserCursorPath = $BuildEnv.registryMountPoint.'Users/Default/NTUSER.DAT' + '\Control Panel\Cursors'

    if ($BuildEnv.cursors.schemes)
    {
        $customSchemes = $BuildEnv.cursors.schemes | Get-Member -MemberType NoteProperty | select -expand Name
        $customSchemes | where { $_ -ne $null } | ForEach-Object {
            $schemeName = $_
            $schemeEntries = $BuildEnv.cursors.schemes."$schemeName" | ForEach-Object { '%SystemRoot%\Cursors\' + $_ }
            $schemeEntries += $schemeName
            $schemeValue = $schemeEntries -join ','
        }

        Get-ItemProperty -Path $schemeBasePath -Name $schemeName -ErrorAction SilentlyContinue -ErrorVariable getPropErr
        if (-not $getPropErr)
        {
            Remove-ItemProperty -Path $schemeBasePath -Name $schemeName
        }
        New-ItemProperty -Path $schemeBasePath -Name $schemeName -PropertyType ExpandString -Value $schemeValue
    }

    if ($BuildEnv.cursors.default)
    {
        Set-ItemProperty -Path $schemeBasePath -Name '(Default)' -Value $BuildEnv.cursors.default.Scheme

        if (-not (Test-Path $defaultBasePath))
        {
            md $defaultBasePath | Out-Null
        }

        $BuildEnv.cursors.default | Get-Member -MemberType NoteProperty | select -expand Name | where { $_ -ne 'Scheme' } | ForEach-Object {
            Set-ItemProperty -Path $defaultBasePath -Name $_ -Value ('%SystemRoot%\Cursors\' + $BuildEnv.cursors.default."$_")
            Set-ItemProperty -Path $userCursorPath -Name $_ -Value ('%SystemRoot%\Cursors\' + $BuildEnv.cursors.default."$_")
            Set-ItemProperty -Path $defaultUserCursorPath -Name $_ -Value ('%SystemRoot%\Cursors\' + $BuildEnv.cursors.default."$_")
        }

        # The Scheme Source specifies the type of cursor scheme that is currently being used. 
        # 0 means default; 1 means user; 2 means system
        Set-ItemProperty -Path $defaultBasePath -Name 'Scheme Source' -Value 2
        Set-ItemProperty -Path $userCursorPath -Name 'Scheme Source' -Value 2
        Set-ItemProperty -Path $defaultUserCursorPath -Name 'Scheme Source' -Value 2
    }
}

task DismountRegistry -depends ModifyRegistry {
	$regFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows/System32/config/SOFTWARE'
	$regPath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'
	$hklmMountPath = 'HKLM\' + $regPath.Substring(6)
    say ("Dismounting registry hive: {0}" -f $hklmMountPath)
	reg.exe UNLOAD $hklmMountPath

    $regFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows/System32/config/DEFAULT'
    $regPath = $BuildEnv.registryMountPoint.'Windows/System32/config/DEFAULT'
    $hkduMountPath = 'HKLM\' + $regPath.Substring(6)
    say ("Dismounting registry hive: {0}" -f $hkduMountPath)
    reg.exe UNLOAD $hkduMountPath

    $regFile = Join-Path $BuildEnv.mountDir -ChildPath 'Users/Default/NTUSER.DAT'
    $regPath = $BuildEnv.registryMountPoint.'Users/Default/NTUSER.DAT'
    $hkuMountPath = 'HKLM\' + $regPath.Substring(6)
    say ("Dismounting registry hive: {0}" -f $hkuMountPath)
    reg.exe UNLOAD $hkuMountPath
}

task CopyFiles -depends Precheck -precondition { $BuildEnv.cursors.schemes -ne $null } {
    $cursorTargetDir = Join-Path $BuildEnv.mountDir -ChildPath 'Windows\Cursors'
    $refAcl = Get-Acl "$cursorTargetDir\aero_arrow.cur"

    $BuildEnv.cursors.schemes | Get-Member -MemberType NoteProperty | select -expand Name | ForEach-Object {
        $cursorFiles = $BuildEnv.cursors.schemes."$_"
        foreach ($fileName in $cursorFiles)
        {
            $resDefaultPath = Join-Path $BuildEnv.resDir -ChildPath $fileName
            $resFallbackPath = Join-Path $BuildEnv.BuildScriptDir -ChildPath $fileName
            $resFile = ''

            if (Test-Path $resDefaultPath -PathType Leaf)
            {
                say ("Found resource file: {0}" -f $resDefaultPath)
                $resFile = $resDefaultPath
            }
            elseif (Test-Path $resFallbackPath -PathType Leaf)
            {
                say ("Found fallback resource file: {0}" -f $resFallbackPath)
                $resFile = $resFallbackPath
            }

            if ($resFile -eq '')
            {
                say ("Resource file not found: {0}" -f $fileName) -v 0
                continue
            }

            say ("Copy {0} --> {1}" -f $resFile, $cursorTargetDir)
            if (Test-Path "$cursorTargetDir\$fileName")
            {
                Grant-AdminFullFileAccess -Path "$cursorTargetDir\$fileName"
                del "$cursorTargetDir\$fileName"
            }
            copy $resFile $cursorTargetDir -Force
            $refAcl | Set-Acl -Path "$cursorTargetDir\$fileName"
        }
    }
}

task Finalize -depends Precheck, DismountRegistry, CopyFiles {
	say 'Done!'
}
