task default -depends Finalize

task Precheck {
	$tokensFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows\SysWOW64\Speech_OneCore\Common\en-US\tokens_TTS_en-US.xml'
	assert (Test-Path $tokensFile -PathType Leaf) ("File not found: {0}" -f $tokensFile)

    $regPath = $BuildEnv.registryMountPoint.'Windows/System32/config/SOFTWARE'
    assert (Test-Path $regPath) ("A required registry hive was not loaded: {0}" -f $regPath)
}

task RegistryCheck -depends Precheck {
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
	say 'Done!'
}
