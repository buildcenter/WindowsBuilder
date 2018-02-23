task default -depends Finalize

task Precheck {
	assert ($BuildEnv.cursors) "The cursors entry is empty or undefined."

    @(
        'Windows/System32/config/SOFTWARE'
        'Windows/System32/config/DEFAULT'
        'Users/Default/NTUSER.DAT'
    ) | ForEach-Object {
        $regPath = $BuildEnv.registryMountPoint."$_"
        assert (Test-Path $regPath) ("A required registry hive was not loaded: {0}" -f $regPath)
    }
}

task ModifyRegistry -depends Precheck {
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

task Finalize -depends ModifyRegistry, CopyFiles {
	say 'Done!'
}
