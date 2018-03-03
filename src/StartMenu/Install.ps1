task default -depends Finalize

task Precheck {
	assert ($BuildEnv.startMenu) "The startMenu entry is empty or undefined."
}

task CustomLayout -depends Precheck {
    if (-not $BuildEnv.startMenu.layout)
    {
        say "The startMenu.layout entry is empty or undefined"
        return
    }

    $layoutFilePath = Join-Path $BuildEnv.resDir -ChildPath $BuildEnv.startMenu.layout
    if (-not (Test-Path $layoutFilePath -PathType Leaf))
    {
        say "The file define by startMenu.layout does not exist: $layoutFilePath" -v 0
        return
    }
    else
    {
        # @WINDOWS-BUG
        # [2018-2-28] We cannot use import-startlayout because there seems to be a bug when mountPath is not a drive:
        # 
        #    Import-StartLayout -LayoutPath $layoutFilePath -MountPath $BuildEnv.mountDir
        #    Could not find a part of the path 'C:\WindowsBuilder\working\mountUsers\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml'.

        say "Applying custom start layout"
        $targetFile = Join-Path $BuildEnv.mountDir -ChildPath 'Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml'
        assert (-not (Test-Path -Path $targetFile -PathType Container)) "The target path is occupied by a folder: $targetFile"

        copy $layoutFilePath $targetFile -Force
    }
}

task Finalize -depends CustomLayout {
	say 'Done!'
}
