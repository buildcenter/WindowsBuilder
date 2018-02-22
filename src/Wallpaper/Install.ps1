task default -depends Finalize

task Precheck {
	assert ($BuildEnv.wallpaper) "The wallpaper entry is empty or undefined."
}

task CopyFiles -depends Precheck {
    $winWebDir = Join-Path $BuildEnv.mountDir -ChildPath 'Windows\Web'
    $wallpaperDir = Join-Path $winWebDir -ChildPath 'Wallpaper'
    $wallpaper4kDir = Join-Path $winWebDir -ChildPath '4K\Wallpaper'

    if ($BuildEnv.wallpaper.removeExtra -eq $true)
    {
        $extraFolders = dir $wallpaperDir -Directory | where { $_.Name -ne 'Windows' } | select -expand FullName
        dir $wallpaper4kDir -Directory | where { $_.Name -ne 'Windows' } | select -expand FullName | ForEach-Object {
            $extraFolders += $_
        }

        $extraFolders | where { $_ -ne $null } | ForEach-Object {
            $targetFolder = $_
            say ("Removing directory: {0}" -f $targetFolder)

            dir $targetFolder -Force | % { Grant-AdminFullFileAccess -Path $_.FullName }
            del "$targetFolder\*.*" -Force
            rd $targetFolder -Recurse -Force
        }
    }

    @(
        'default'
        'default4k-1024x768'
        'default4k-1200x1920'
        'default4k-1366x768'
        'default4k-1600x2560'
        'default4k-2160x3840'
        'default4k-2560x1600'
        'default4k-3840x2160'
        'default4k-768x1024'
        'default4k-768x1366'
    ) | ForEach-Object {
        if ($BuildEnv.wallpaper."$_") 
        {
            $resDefaultFilePath = Join-Path $BuildEnv.resDir -ChildPath $BuildEnv.wallpaper."$_"
            $resFallbackFilePath = Join-Path $BuildEnv.BuildScriptDir -ChildPath $BuildEnv.wallpaper."$_"
            $resFilePath = ''

            if (Test-Path $resDefaultFilePath -PathType Leaf)
            {
                say ("Replacing {0}" -f $_)
                $resFilePath = $resDefaultFilePath
            }
            elseif (Test-Path $resFallbackFilePath -PathType Leaf)
            {
                say ("Replacing with fallback resource: {0}" -f $_)
                $resFilePath = $resFallbackFilePath
            }
            else
            {
                say ("[!] Resource not found: {0}" -f $_) -v 0
            }

            if ($resFilePath)
            {
                $targetFilePath = $(
                    if ($_ -eq 'default')
                    {
                        Join-Path $BuildEnv.mountDir -ChildPath 'Windows\Web\Wallpaper\Windows\img0.jpg'
                    }
                    else
                    {
                        Join-Path $BuildEnv.mountDir -ChildPath ('Windows\Web\4K\Wallpaper\Windows\img0_{0}.jpg' -f $_.Split('-')[1])
                    }
                )

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
}

task Finalize -depends Precheck, CopyFiles {
	say 'Done!'
}
