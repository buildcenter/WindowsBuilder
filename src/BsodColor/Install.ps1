task default -depends Finalize

task Precheck {
	assert ($BuildEnv.bsodColor) "The bsod entry is empty or undefined."

    $colorMap = @{
        black = '0'
        green = '1'
        cyan = '3'
        red = '4'
        magenta = '5'
        yellow = '6'
        white = '7'
        gray = '8'
        brightBlue = '9'
        brightGreen = 'A'
        brightCyan = 'B'
        brightRed = 'C'
        brightMagenta = 'D'
        brightYellow = 'E'
        brightWhite = 'F'
    }

    assert ($BuildEnv.bsodColor.background -in $colorMap.Keys) ("Only the following colors are supported for property 'bsodColor.background': {0}" -f ($colorMap.Keys -join ', '))
    assert ($BuildEnv.bsodColor.foreground -in $colorMap.Keys) ("Only the following colors are supported for property 'bsodColor.foreground': {0}" -f ($colorMap.Keys -join ', '))
}

task ModifySystemIni -depends Precheck {
    $systemIni = Join-Path $BuildEnv.mountDir -ChildPath 'Windows\system.ini'

    $systemIniContent = Get-Content -Path $systemIni

    $customBgColorExist = $false
    $customFgColorExist = $false

    $colorMap = @{
        black = '0'
        green = '1'
        cyan = '3'
        red = '4'
        magenta = '5'
        yellow = '6'
        white = '7'
        gray = '8'
        brightBlue = '9'
        brightGreen = 'A'
        brightCyan = 'B'
        brightRed = 'C'
        brightMagenta = 'D'
        brightYellow = 'E'
        brightWhite = 'F'
    }

    $bgColor = $colorMap."$($BuildEnv.bsodColor.background)"
    $fgColor = $colorMap."$($BuildEnv.bsodColor.foreground)"

    $newContent = @()    
    for ($i = 0; $i -lt $systemIniContent.Count; $i++)
    {
        if ($systemIniContent[$i] -eq '[386Enh]')
        {
            $newContent += $systemIniContent[$i]
            
            for ($j = $i + 1; $j -lt $systemIniContent.Count; $j++)
            {
                if ($systemIniContent[$j] -like 'MessageBackColor=*')
                {
                    say ("Change line '{0}' to '{1}'" -f $systemIniContent[$j], ('MessageBackColor={0}' -f $bgColor))
                    $customBgColorExist = $true
                    $newContent += 'MessageBackColor={0}' -f $bgColor
                }
                elseif ($systemIniContent[$j] -like 'MessageTextColor=*')
                {
                    say ("Change line '{0}' to '{1}'" -f $systemIniContent[$j], ('MessageTextColor={0}' -f $fgColor))
                    $customFgColorExist = $true
                    $newContent += 'MessageTextColor={0}' -f $fgColor
                }
                elseif ($systemIniContent[$j] -eq '')
                {
                    if ($customBgColorExist -eq $false)
                    {
                        say ("Setting background color to {0}" -f $bgColor)
                        $newContent += 'MessageBackColor={0}' -f $bgColor
                    }
                    if ($customFgColorExist -eq $false)
                    {
                        say ("Setting background color to {0}" -f $fgColor)
                        $newContent += 'MessageTextColor={0}' -f $fgColor
                    }

                    $newContent += ''
                    $i = $j
                    break
                }
                else
                {
                    $newContent += $systemIniContent[$j]
                    continue
                }
            }
        }
        else
        {
            $newContent += $systemIniContent[$i]
        }
    }

    say 'Saving changes'
    $newContent | Set-Content $systemIni
}

task Finalize -depends ModifySystemIni {
	say 'Done!'
}
