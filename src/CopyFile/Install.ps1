task default -depends Finalize

task Precheck {
	assert ($BuildEnv.copyFile) "The copyFile entry is empty or undefined."
}

task CopyFiles -depends Precheck {
    $allSrc = $BuildEnv.copyFile | Get-Member -MemberType NoteProperty | select -expand Name

    $allSrc | ForEach-Object {
        $srcPath = Join-Path $BuildEnv.resDir -ChildPath $_
        if (-not (Test-Path $srcPath))
        {
            say ("The source cannot be found: {0}" -f $srcPath) -v 0
        }
        else
        {
            $targetPath = Join-Path $BuildEnv.mountDir -ChildPath $BuildEnv.copyFile."$_"
            $targetPathParent = Split-Path $targetPath -Parent
            if (-not (Test-Path $targetPathParent))
            {
                say ("Creating target directory: $targetPathParent")
                md $targetPathParent -Force | Out-Null

            }

            say ("Copying {0} -> {1}" -f $srcPath, $targetPath)

            if ($targetPath.EndsWith('\'))
            {
                copy $srcPath $targetPath -Recurse -Force
            }
            else
            {
                copy $srcPath $targetPath -Force
            }
        }
    }
}

task Finalize -depends Precheck, CopyFiles {
	say 'Done!'
}
