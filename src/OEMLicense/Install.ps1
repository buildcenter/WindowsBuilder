task default -depends Finalize

task Precheck {
	assert ($BuildEnv.oemLicense.rtfLicense) "The oemLicense.rtfLicense entry is empty or undefined."
}

task CopyFiles -depends Precheck {
    $srcFile = Join-Path $BuildEnv.resDir -ChildPath $BuildEnv.oemLicense.rtfLicense

    if (-not (Test-Path $srcFile))
    {
        say ("Source file not found: $srcFile") -v 0
        return
    }

    if (-not $BuildEnv.oemLicense.language)
    {
        $userLang = 'en-US'
    }
    else
    {
        $userLang = $BuildEnv.oemLicense.language
    }

    $targetFile = Join-Path $BuildEnv.mountDir -ChildPath "windows\System32\$userLang\Licenses\Volume\Enterprise\license.rtf"

	$origAcl = Get-Acl $targetFile
	Grant-AdminFullFileAccess -Path $targetFile

	say "Replacing target file"

	copy $srcFile $targetFile -Force
	$origAcl | Set-Acl -Path $targetFile
}

task Finalize -depends CopyFiles {
	say 'Done!'
}
