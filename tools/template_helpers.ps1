function concat
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]$InputObject,

        [parameter(Position = 1)]
        [AllowEmptyString()]
        [string[]]$AppendWith = @('')
    )

    Begin
    {
        $appendText = $AppendWith -join ''
    }

    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        foreach ($inputItem in $InputObject)
        {
            if ($AppendWith)
            {
                '{0}{1}' -f $inputItem, $appendText
            }
            else
            {
                $inputItem
            }
        }
    }
}

function format
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]$InputObject,

        [parameter(Mandatory, Position = 1)]
        [AllowEmptyString()]
        [string]$With
    )
    
    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        foreach ($inputItem in $InputObject)
        {
            if (-not $inputItem)
            {
                $With -f ''
            }
            else
            {
                $With -f $inputItem
            }
        }
    }
}

function include
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Path,

        [parameter()]
        [string]$Indent,

        [parameter()]
        [ValidateSet('Ascii', 'Unicode', 'UTF8')]
        [string]$Encoding
    )

    if ((-not $Indent) -and (-not $Encoding))
    {
        Get-Content -Path $Path -Raw
    }
    else
    {
        $getContentParam = @{
            Path = $Path
        }

        if ($Encoding)
        {
            $getContentParam.Encoding = $Encoding
        }

        (Get-Content @getContentParam | ForEach-Object {
            if ($Indent)
            {
                $Indent + $_
            }
            else
            {
                $_
            }
        }) -join [Environment]::NewLine
    }
}

function lowercase
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]$InputObject,

        [parameter()]
        [int]$First = -1
    )

    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        foreach ($inputItem in $InputObject)
        {
            if (($inputItem -ne $null) -and ($inputItem -is [string]))
            {
                if (($First -lt 1) -or ($inputItem.Length -le $First))
                {
                    $inputItem.ToLowerInvariant()
                }
                else
                {
                    $inputItem.Substring(0, $First).ToLowerInvariant() + $inputItem.Substring($First)
                }
            }
            else
            {
                $null
            }
        }
    }
}

function uppercase
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]$InputObject,

        [parameter()]
        [int]$First = -1
    )

    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        foreach ($inputItem in $InputObject)
        {
            if (($inputItem -ne $null) -and ($inputItem -is [string]))
            {
                if (($First -lt 1) -or ($inputItem.Length -le $First))
                {
                    $inputItem.ToUpperInvariant()
                }
                else
                {
                    $inputItem.Substring(0, $First).ToUpperInvariant() + $inputItem.Substring($First)
                }
            }
            else
            {
                $null
            }
        }
    }
}

function replace
{
    [CmdletBinding(DefaultParameterSetName = 'ReplaceEntireStringSet')]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]$InputObject,

        [parameter(Mandatory, ParameterSetName = 'ReplaceNullSet')]
        [parameter(ParameterSetName = 'ReplaceSubstringSet')]
        [parameter(ParameterSetName = 'ReplaceEntireStringSet')]
        [AllowEmptyString()]
        [Alias('null')]
        [string]$NullOrEmpty,

        [parameter(Mandatory, Position = 1, ParameterSetName = 'ReplaceSubstringSet')]
        [string[]]$Substring,

        [parameter(Position = 2, ParameterSetName = 'ReplaceSubstringSet')]
        [parameter(ParameterSetName = 'ReplaceEntireStringSet')]
        [AllowEmptyString()]
        [string]$With = ''
    )

    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        foreach ($inputItem in $InputObject)
        {
            if ($PSBoundParameters.ContainsKey('NullOrEmpty') -and 
                (-not $inputItem))
            {
                $NullOrEmpty
                continue
            }

            if ($PSCmdlet.ParameterSetName -eq 'ReplaceSubstringSet')
            {
                if (-not $inputItem) 
                { 
                    '' 
                }
                else 
                {
                    $replaceResult = $inputItem
                    foreach ($SubstringItem in $Substring)
                    {
                        $replaceResult = $replaceResult.Replace($SubstringItem, $With) 
                    }
                    $replaceResult
                }
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'ReplaceEntireStringSet')
            {
                $With
            }
            else
            {
                $inputItem
            }
        }
    }
}

function bool
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [psobject[]]$InputObject,

        [parameter()]
        [validateSet('true', 'false')]
        [string]$NullOrEmpty = 'false',

        [parameter()]
        [string]$TrueText = 'true',

        [parameter()]
        [string]$FalseText = 'false'
    )

    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        foreach ($inputItem in $InputObject)
        {
            if ($inputItem -eq $true)
            {
                $TrueText
            }
            elseif ($inputItem -eq $false)
            {
                $FalseText
            }
            else
            {
                if (($NullOrEmpty -ne 'false') -and 
                    (($inputItem -eq $null) -or ($inputItem -eq '')))
                {
                    $TrueText
                }
                else
                {
                    $FalseText
                }
            }
        }
    }
}

function xmltext
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]$InputObject
    )

    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        # replace & first!
        foreach ($inputItem in $InputObject)
        {
            $inputItem.Replace(
                '&', '&amp;'
            ).Replace(
                '<', '&lt;'
            ).Replace(
                '>', '&gt;'
            )
        }
    }
}

function xmlattrib
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]$InputObject
    )

    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        # replace & first!
        foreach ($inputItem in $InputObject)
        {
            $inputItem.Replace(
                '&', '&amp;'
            ).Replace(
                '<', '&lt;'
            ).Replace(
                '>', '&gt;'
            ).Replace(
                '"', '&quot;'
            )
        }
    }
}

function array
{
	[CmdletBinding()]
	param(
		[parameter(Mandatory, ValueFromPipeline = $true)]
		[AllowEmptyString()]
		[AllowNull()]
		$InputObject,

		[parameter()]
		[string]$KeyName = 'name'
	)

	Process
	{
		if ($InputObject -eq $null)
		{
			return $null
		}

		if (($InputObject -isnot [hashtable]) -and ($InputObject -isnot [psobject]))
		{
			return $InputObject
		}

		if ($InputObject -is [hashtable])
		{
			$propNames = $InputObject.Keys
		}
		elseif ($InputObject -is [psobject])
		{
			$propNames = $InputObject | Get-Member -MemberType NoteProperty | select -expand Name
		}

		$propNames | where { $_ -ne $null } | ForEach-Object {
				$propKey = $_
				$propValue = $InputObject."$propKey"

				if ($propValue -is [psobject])
				{
					if ($propValue."$KeyName")
					{
						$propValue."$KeyName" = $propKey
					}
					else
					{
						$propValue | Add-Member -MemberType NoteProperty -Name $KeyName -Value $propKey
					}
					
					$propValue
				}
				else
				{
					$outItem = New-Object PSObject
					$outItem | Add-Member -MemberType NoteProperty -Name $KeyName -Value $propKey
					$outItem | Add-Member -MemberType NoteProperty -Name Value -Value $propValue
					$outItem
				}
			}
		}
	}
}

function stringdata
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$InputObject
    )

    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        # This is the same as ConvertFrom-StringData but we use ` instead of \ as the escape char
        # Chars you can escape with `:
        # - https://msdn.microsoft.com/library/system.text.regularexpressions.regex.unescape
        #
        # Escape ` itself with a double (``)

        # we need to escape `` so it turns out as `
        # encodeAs is just an arbitary string. you don't need to escape encodeAs but choosing something unique helps with the speed

        $escapeChar = '`'
        $reserved = $escapeChar * 2
        $encodeAs = '^~^'

        $inputEscaped = $InputObject.Replace($encodeAs, $encodeAs + '2').Replace($reserved, $encodeAs + '1')

        $hashtableResult = ConvertFrom-StringData $inputEscaped.Replace('\', '\\').Replace($escapeChar, '\')
        $hashtableResult.Keys | ForEach-Object {
            $valueUnescaped = $hashtableResult."$_".Replace($encodeAs + '1', $reserved).Replace($encodeAs + 2, $encodeAs).Replace($reserved, $escapeChar)

            $outItem = New-Object PSObject
            $outItem | Add-Member -MemberType NoteProperty -Name Name -Value $_
            $outItem | Add-Member -MemberType NoteProperty -Name Value -Value $valueUnescaped

            $outItem
        }
    }
}
