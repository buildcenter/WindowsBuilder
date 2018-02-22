task default -depends Finalize

task Precheck {
	assert ($BuildEnv.accountPicture) "The accountPicture entry is empty or undefined."
}

task CopyFiles -depends Precheck {
    $userPicDir = Join-Path $BuildEnv.mountDir -ChildPath 'ProgramData\Microsoft\User Account Pictures'

    $fileMap = @{
        'guestBmp' = 'guest.bmp'
        'guestPng' = 'guest.png'
        'userBmp' = 'user.bmp'
        'userPng' = 'user.png'
        'user32' = 'user-32.png'
        'user40' = 'user-40.png'
        'user48' = 'user-48.png'
        'user192' = 'user-192.png'
    }

    $fileMap.Keys | ForEach-Object {
        $targetFile = Join-Path $userPicDir -ChildPath $fileMap."$_"
        if (-not (Test-Path $targetFile -PathType Leaf))
        {
            say ("Target file not found: {0}" -f $fileMap."$_") -v 0
        }
        else
        {
            $resDefaultPath = Join-Path $BuildEnv.resDir -ChildPath $BuildEnv.accountPicture."$_"
            $resFallbackPath = Join-Path $BuildEnv.BuildScriptDir -ChildPath $BuildEnv.accountPicture."$_"
            $resFile = ''

            if ($BuildEnv.accountPicture."$_")
            {
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
            }

            if ($resFile -eq '')
            {
                say ("Resource is not defined or does not exist: {0}" -f $_) -v 0
            }
            else
            {
                say ("Replacing {0} <-- {1}" -f $targetFile, $resFile)
                $refAcl = Get-Acl $targetFile
                del $targetFile -Force
                copy $resFile $targetFile
                $refAcl | Set-Acl -Path $targetFile
            }
        }
    }
}

task Finalize -depends Precheck, CopyFiles {
	say 'Done!'
}
