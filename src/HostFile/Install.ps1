task default -depends Finalize

task Precheck {
	assert ($BuildEnv.'hostFile') "The 'hostFile' entry is empty or undefined."
}

task AddHostFileBlockEntry -depends Precheck -precondition { $BuildEnv.hostFile.block.Count -ne 0 } {
	$hostFile = Join-Path $BuildEnv.mountDir -ChildPath 'Windows\System32\Drivers\etc\hosts'
	$hostFileEntries = Get-Content $hostFile | where { 
		($_ -ne $null) -and 
		($_ -ne '') -and 
		(-not $_.StartsWith('#')) 
	}

	$hostBlockEntries = $hostFileEntries | where { 
		$_.StartsWith('0.0.0.0        ') -and 
		$_.EndsWith('# Blocked by vendor') 
	} | ForEach-Object {
		$_.Substring('0.0.0.0        '.Length).Split(' ')[0]
	}

	$newHostBlockEntries = @()

	$BuildEnv.hostFile.block | where { 
		($_ -ne $null) -and 
		($_ -ne '') 
	} | select -Unique | ForEach-Object {
		if ($_ -in $hostBlockEntries)
		{
			say ("Not adding entry because it already exists: {0}" -f $_)
		}
		else
		{
			$spaceDelimCount = 48 - $_.Length
			if ($spaceDelimCount -gt 0)
			{
				$spaceDelim = ' ' * $spaceDelimCount
			}
			else
			{
				$spaceDelim  = ' '
			}

			$newHostBlockEntries += ('0.0.0.0        {0}{1}# Blocked by vendor' -f $_, $spaceDelim)
		}
	}

	say "The following entries will be added to the image host file:"
	$newHostBlockEntries 

	$newHostBlockEntries | Add-Content $hostFile
}

task Finalize -depends AddHostFileBlockEntry {
	say 'Done!'
}
