task default -depends Finalize

task Precheck {
	assert ($BuildEnv.lockScreen) "The lockScreen entry is empty or undefined."
}

task CopyFiles -depends Precheck {
    $winWebDir = Join-Path $BuildEnv.mountDir -ChildPath 'Windows\Web'
    $lockscreenDir = Join-Path $winWebDir -ChildPath 'Screen'

    if ($BuildEnv.lockScreen.removeExtra -eq $true)
    {
        $extraFiles = dir $lockscreenDir -File | where { $_.Name -ne 'img100.jpg' } | select -expand FullName
        $extraFiles | where { $_ -ne $null } | ForEach-Object {
            $targetFile = $_
            say ("Removing file: {0}" -f $targetFile)

            Grant-AdminFullFileAccess -Path $targetFile
            del $targetFile -Force
        }
    }

    if ($BuildEnv.lockscreen.default) 
    {
        $resDefaultFilePath = Join-Path $BuildEnv.resDir -ChildPath $BuildEnv.lockscreen.default
        $resFallbackFilePath = Join-Path $BuildEnv.BuildScriptDir -ChildPath $BuildEnv.lockscreen.default
        $resFilePath = ''

        if (Test-Path $resDefaultFilePath -PathType Leaf)
        {
            say ("Replacing {0}" -f "default")
            $resFilePath = $resDefaultFilePath
        }
        elseif (Test-Path $resFallbackFilePath -PathType Leaf)
        {
            say ("Replacing with fallback resource: {0}" -f "default")
            $resFilePath = $resFallbackFilePath
        }
        else
        {
            say ("[!] Resource not found: {0}" -f "default") -v 0
        }

        if ($resFilePath)
        {
            $targetFilePath = Join-Path $BuildEnv.mountDir -ChildPath 'Windows\Web\Screen\img100.jpg'

            if (Test-Path $targetFilePath)
            {
                $refAcl = Get-Acl $targetFilePath
                Grant-AdminFullFileAccess -Path $targetFilePath
                del $targetFilePath -Force
                copy $resFilePath $targetFilePath
                $refAcl | Set-Acl -Path $targetFilePath
            }
            else
            {
                say ("Target file does not exist: {0}" -f $targetFilePath) -v 0
            }
        }
    }
}

task Finalize -depends Precheck, CopyFiles {
	say 'Done!'
}
