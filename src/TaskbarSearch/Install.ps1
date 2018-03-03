task default -depends Finalize

task Precheck {
	assert ($BuildEnv.taskbarSearch) "The taskbarSearch entry is empty or undefined."

    @(
        'Users/Default/NTUSER.DAT'
    ) | ForEach-Object {
        $regPath = $BuildEnv.registryMountPoint."$_"
        assert (Test-Path $regPath) ("A required registry hive was not loaded: {0}" -f $regPath)
    }
}

task ModifyRegistry -depends Precheck {
    $searchSettingPath = $BuildEnv.registryMountPoint.'Users/Default/NTUSER.DAT' + '\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'

    if (-not (Test-Path $searchSettingPath))
    {
        say ("Creating registry key...")
        $regkey = md $searchSettingPath
        $regkey.Dispose()
    }

    [gc]::Collect()
    
    if ($BuildEnv.taskbarSearch.displayMode -eq 'Hidden')
    {
        say ("Setting display mode to hidden")
        Set-ItemProperty $searchSettingPath -Name SearchboxTaskbarMode -Value 0
    }
    elseif ($BuildEnv.taskbarSearch.displayMode -eq 'Icon')
    {
        say ("Setting display mode to icon")
        Set-ItemProperty $searchSettingPath -Name SearchboxTaskbarMode -Value 1
    }
    elseif ($BuildEnv.taskbarSearch.displayMode -eq 'Full')
    {
        say ("Setting display mode to full")
        Set-ItemProperty $searchSettingPath -Name SearchboxTaskbarMode -Value 2
    }
    else
    {
        say ("Unrecognized display mode value: {0}" -f $BuildEnv.taskbarSearch.displayMode) -v 0
    }
}

task Finalize -depends ModifyRegistry {
	say 'Done!'
}
