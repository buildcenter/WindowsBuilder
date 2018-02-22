will {
	$hklmMountPath = 'HKLM\' + $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'.Substring(6)
    if (Test-Path $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE')
    {
        say ("Dismounting registry hive: {0}" -f $hklmMountPath)
        reg.exe UNLOAD $hklmMountPath
    }
    else
    {
    	say ("Registry hive does not require dismounting because it has not been loaded yet: {0}" -f $hklmMountPath)
    }
}

task default -depends Finalize

task Precheck {
	$tokensFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows\SysWOW64\Speech_OneCore\Common\en-US\tokens_TTS_en-US.xml'
	assert (Test-Path $tokensFile -PathType Leaf) ("File not found: {0}" -f $tokensFile)
    assert ($BuildEnv.tts.enable -eq $true) ("The property 'tts.enable' must be set to 'true'")
}

task MountRegistry -depends Precheck {
	$regFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows/System32/config/SOFTWARE'
	$regPath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'
	$hklmMountPath = 'HKLM\' + $regPath.Substring(6)
    say ("Mounting registry hive to host: {0} --> {1}" -f $regFile, $hklmMountPath)
 	reg.exe LOAD $hklmMountPath $regFile
}

task RegistryCheck -depends MountRegistry {
	# omit the 'SOFTWARE' reg path prefix	
	$regPath = Join-Path $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE' -ChildPath 'Microsoft\Speech'
	assert (Test-Path $regPath) ("Registry key not found: {0}" -f $regPath)
}

task CopyFiles -depends RegistryCheck {
	$tokensFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows\SysWOW64\Speech_OneCore\Common\en-US\tokens_TTS_en-US.xml'
	say "Modifying acl: $tokensFile"
	$origAcl = Get-Acl $tokensFile
	Grant-AdminFullFileAccess -Path $tokensFile

	say "Replacing tokens file: $tokensFile"
	copy "$($BuildEnv.BuildScriptDir)\tokens_TTS_en-US.xml" (Split-Path $tokensFile -Parent) -Force
	Set-Acl -Path $tokensFile -AclObject $origAcl	
}

task ImportRegistry -depends CopyFiles {
	$regPath = Join-Path $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE' -ChildPath 'Microsoft\Speech'
	$regLegacyPath = $regPath.Replace('HKLM:\', 'HKEY_LOCAL_MACHINE\')

	dir "$($BuildEnv.BuildScriptDir)\*.reg" | ForEach-Object {
		copy $_ $BuildEnv.tempDir
		$regFile = Join-Path $BuildEnv.tempDir -ChildPath $_.Name
		((Get-Content $_) -join "`r`n").Replace('[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech', '[' + $regLegacyPath) | Set-Content "$regFile"
		say "Importing registry: $regFile"
		reg.exe IMPORT "$regFile"	
	}
}

task Finalize -depends ImportRegistry {
	$hklmMountPath = 'HKLM\' + $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'.Substring(6)
    say ("Dismounting registry hive at mount point: {0}" -f $hklmMountPath)
	reg.exe UNLOAD $hklmMountPath

	say 'Done!'
}
