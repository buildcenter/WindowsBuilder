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
	assert ($BuildEnv.startupSound) "The startupSound entry is empty or undefined."
}

task MountRegistry -depends Precheck {
    $regFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows/System32/config/SOFTWARE'
    $regPath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'
    $hklmMountPath = 'HKLM\' + $regPath.Substring(6)

    say ("Mounting registry to hive: {0} --> {1}" -f $regFile, $hklmMountPath)
    reg.exe LOAD $hklmMountPath $regFile
}

task ModifyRegistry -depends MountRegistry {
    say "Enabling startup sound..."    

    $regBase = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'

    # HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation
    Set-ItemProperty "$regBase\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" -Name DisableStartupSound -Value 0

    # HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    #Set-ItemProperty "$regBase\Microsoft\Windows\Policies\System" -Name DisableStartupSound -Value 0
}

task DismountRegistry -depends ModifyRegistry {
    $regFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows/System32/config/SOFTWARE'
    $regPath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'
    $hklmMountPath = 'HKLM\' + $regPath.Substring(6)
    say ("Dismounting registry hive: {0}" -f $hklmMountPath)
    reg.exe UNLOAD $hklmMountPath
}

task ModifyFile -depends DismountRegistry {
    $targetFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows\System32\imageres.dll'
    if (-not ($BuildEnv.startupSound.waveFile))
    {
        say ("You need to define startupSound.waveFile")
        return
    }

    $resDefaultPath = Join-Path $BuildEnv.resDir -ChildPath $BuildEnv.startupSound.waveFile
    $resFallbackPath = Join-Path $BuildEnv.BuildScriptDir -ChildPath $BuildEnv.startupSound.waveFile
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
        say ("Resource is not defined or does not exist: {0}" -f $BuildEnv.startupSound.waveFile)
        return
    }

    $resFile = Resolve-Path $resFile | select -expand Path

    say ("Copying image file to temp...")
    copy $targetFile "$($BuildEnv.tempDir)\imageres_orig.dll" -Force

    say ("Modifying image file...")
    Start-Process -FilePath "$($BuildEnv.BuildScriptDir)\ResourceHacker.exe" -ArgumentList "-addoverwrite $($BuildEnv.tempDir)\imageres_orig.dll, $($BuildEnv.tempDir)\imageres.dll, $resFile, wave, 5080," -Wait

    say ("Replacing file {0} <-- {1}" -f $targetFile, "$($BuildEnv.tempDir)\imageres.dll")
    $refAcl = Get-Acl $targetFile
    Grant-AdminFullFileAccess -Path $targetFile
    del $targetFile
    copy "$($BuildEnv.tempDir)\imageres.dll" $targetFile -Force
    $refAcl | Set-Acl -Path $targetFile
}

task Finalize -depends Precheck, ModifyFile {
	say 'Done!'
}
