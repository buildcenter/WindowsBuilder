task default -depends Finalize

task Precheck {
	assert ($BuildEnv.soundTheme) "The soundTheme entry is empty or undefined."

    @(
        'Users/Default/NTUSER.DAT'
    ) | ForEach-Object {
        $regPath = $BuildEnv.registryMountPoint."$_"
        assert (Test-Path $regPath) ("A required registry hive was not loaded: {0}" -f $regPath)
    }
}

task ModifyRegistry -depends Precheck {
    $themeNames = $BuildEnv.soundTheme | Get-Member -MemberType NoteProperty | select -expand Name
    $reservedNames = @('mountRegistryHive', 'disabled')

    $themeNames | where { ($_ -ne '') -and ($_ -notin $reservedNames) } | ForEach-Object {
        $refName = $_
        $themeInfo = $BuildEnv.soundTheme."$_"

        $displayName = $themeInfo.displayName
        if (-not $displayName)
        {
            $displayName = $refName
        }

        say ("Sound scheme '{0}' display as '{1}'" -f $refName, $displayName)

        $isDefault = $false
        if ($themeInfo.isDefault -eq $true)
        {
            $isDefault = $true
            say ("This sound scheme will be set as the system default.")
        }

        $appNameList = $null
        if ($themeInfo.apps)
        {
            $appNameList = $themeInfo.apps | Get-Member -MemberType NoteProperty | select -expand Name
        }

        if (-not $appNameList)
        {
            say ('The sound scheme did not define any "apps" event: {0}' -f $refName) -v 0
        }
        else
        {
            $appBasePath = $BuildEnv.registryMountPoint.'Users/Default/NTUSER.DAT' + '\AppEvents\Schemes'
            $schemeInfoPath = $appBasePath + '\Names\' + $refName

            if (-not (Test-Path $schemeInfoPath))
            {
                $schemeReg = md $schemeInfoPath -Force
                $schemeReg.Dispose()
            }

            say ("Creating theme profile")
            Set-ItemProperty -Path $schemeInfoPath -Name '(Default)' -Value $displayName

            if ($isDefault -eq $true)
            {
                say ("Setting theme as default")
                Set-ItemProperty -Path $appBasePath -Name '(Default)' -Value $refName
            }

            # app events
            $appNameList | ForEach-Object {
                $appName = $_
                $appEventBasePath = $appBasePath + '\Apps\' + $appName

                if (-not $themeInfo.apps."$appName")
                {
                    say ("The sound scheme app event '{0}\apps\{1}' is empty" -f $refName, $appName)
                }
                else
                {
                    if (-not (Test-Path $appEventBasePath))
                    {
                        $appEventReg = md $appEventBasePath -Force
                        $appEventReg.Dispose()
                    }

                    $eventNames = $themeInfo.apps."$appName" | Get-Member -MemberType NoteProperty | select -expand Name
                    $eventNames | ForEach-Object {
                        $propName = $_
                        $propValue = $themeInfo.apps."$appName"."$propName"
                        $propPath = $appEventBasePath + '\' + $propName + '\' + $refName

                        if (-not (Test-Path $propPath))
                        {
                            $appEventPropReg = md $propPath -Force
                            $appEventPropReg.Dispose()
                        }

                        say ("Setting app event: {0}\{1}\{2} = {3}" -f $appName, $propName, $refName, $propValue)
                        Set-ItemProperty -Path $propPath -Name '(Default)' -Value $propValue

                        if ($isDefault -eq $true)
                        {
                            $currentPropPath = $appEventBasePath + '\' + $propName + '\.Current'
                            if (-not (Test-Path $currentPropPath))
                            {
                                $appEventCurrentReg = md $currentPropPath -Force
                                $appEventCurrentReg.Dispose()
                            }

                            say ("Setting app event: {0}\{1}\{2} = {3}" -f $appName, $propName, '.Current', $propValue)
                            Set-ItemProperty -Path $currentPropPath -Name '(Default)' -Value $propValue
                        }
                    }
                }
            }
        }
    }
}

task CopyFiles -depends Precheck {
    $themeNames = $BuildEnv.soundTheme | Get-Member -MemberType NoteProperty | select -expand Name
    $refAcl = Get-Acl (Join-Path $BuildEnv.mountDir -ChildPath 'Windows\Media\Windows Default.wav')
    $refFolderAcl = Get-Acl (Join-Path $BuildEnv.mountDir -ChildPath 'Windows\Media')

    $themeNames | where { $_ -ne '' } | ForEach-Object {
        $refName = $_
        $themeFiles = $BuildEnv.soundTheme."$_".files

        if ($themeFiles.Count -eq 0)
        {
            say ("The theme {0} has no files." -f $refName)
        }
        else
        {
            $filesList = @{}
            $themeFiles | ForEach-Object {
                $defaultResPath = Join-Path $BuildEnv.resDir -ChildPath $_
                $fallbackResPath = Join-Path $BuildEnv.BuildScriptDir -ChildPath $_

                if (Test-Path $defaultResPath -PathType Leaf)
                {
                    say ("Found resource file: {0}" -f $defaultResPath)
                    $filesList."$_" = $defaultResPath
                }
                elseif (Test-Path $fallbackResPath -PathType Leaf)
                {
                    say ("Found fallback resource file: {0}" -f $fallbackResPath)
                    $filesList."$_" = $fallbackResPath
                }
                else
                {
                    say ("The resource file was not found: {0}" -f $_) -v 0
                }
            }

            $filesList.Keys | where { $_ -ne '' } | ForEach-Object {
                $resFile = $filesList."$_"
                $targetFile = Join-Path $BuildEnv.mountDir -ChildPath ('Windows\Media\' + $_)
                $targetFileParent = Split-Path $targetFile -Parent
                if (-not (Test-Path $targetFileParent -PathType Container))
                {
                    md $targetFileParent -Force | Out-Null
                    $refFolderAcl | Set-Acl -Path $targetFileParent
                }

                if (Test-Path $targetFile)
                {
                    Grant-AdminFullFileAccess -Path $targetFile
                    del $targetFile -Force
                }

                say ("Copy {0} --> {1}" -f $resFile, $targetFile)
                copy $resFile $targetFile -Force
                $refAcl | Set-Acl -Path $targetFile
            }
        }
    }
}

task Finalize -depends ModifyRegistry, CopyFiles {
	say 'Done!'
}
