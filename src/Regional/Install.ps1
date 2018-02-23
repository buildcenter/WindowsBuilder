task default -depends Finalize

task Precheck {
	assert ($BuildEnv.regional) "The regional entry is empty or undefined."

    @(
        'Users/Default/NTUSER.DAT'
    ) | ForEach-Object {
        $regPath = $BuildEnv.registryMountPoint."$_"
        assert (Test-Path $regPath) ("A required registry hive was not loaded: {0}" -f $regPath)
    }
}

task ModifyRegistry -depends Precheck {
    $regionalSettingNames = $BuildEnv.regional | Get-Member -MemberType NoteProperty | select -expand Name
    $reservedNames = @('mountRegistryHive', 'disabled')

    $regIntlBasePath = $BuildEnv.registryMountPoint."Users/Default/NTUSER.DAT" + '\Control Panel\International'

    $regionalSettingNames | where { ($_ -ne '') -and ($_ -notin $reservedNames) } | ForEach-Object {
        $propName = $_
        $propValue = $BuildEnv.regional."$_"

        say ("Set regional property {0} = {1}" -f $propName, $propValue)
        Set-ItemProperty -Path $regIntlBasePath -Name $propName -Value $propValue
    }
}

task Finalize -depends ModifyRegistry {
	say 'Done!'
}
