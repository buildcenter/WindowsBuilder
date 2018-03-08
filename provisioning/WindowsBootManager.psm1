function Get-WindowsBootManager
{
    [CmdletBinding(DefaultParameterSetName = 'OnlineSet')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'OfflineSet')]
        [string]$StorePath,

        [Parameter(Mandatory, ParameterSetName = 'OnlineSet')]
        [switch]$Online
    )

    Get-WindowsBootRecord -All @PSBoundParameters | where { $_.entryType -eq 'Windows Boot Manager' }
}

function Get-WindowsBootRecord
{
    [CmdletBinding(DefaultParameterSetName = 'OnlineSet')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'OfflineSet')]
        [string]$StorePath,

        [Parameter(Mandatory, ParameterSetName = 'OnlineSet')]
        [switch]$Online,

        [Parameter()]
        [switch]$All
    )

    if ($StorePath)
    {
        $bcdBootEnum = bcdedit.exe /store "$StorePath" /v
    }
    else
    {
        $bcdBootEnum = bcdedit.exe /v
    }

    for ($i = 0; $i -lt $bcdBootEnum.Count; $i++)
    {
        if ($bcdBootEnum[$i] -like '--------*')
        {
            $bootEntryName = $bcdBootEnum[$i - 1]
            $bcdBootEntry = @{}

            $lastPropName = ''
            for ($j = $i + 1; $j -lt $bcdBootEnum.Count; $j++)
            {
                $enumLine = $bcdBootEnum[$j]
                $propName = $enumLine.Split(" ")[0]

                if ($enumLine.StartsWith(' '))
                {
                    $bcdBootEntry."$lastPropName" = @($bcdBootEntry."$lastPropName", $enumLine.TrimStart())
                }
                elseif ($propName -eq '')
                {
                    $i = $j
                    break
                }
                else
                {
                    $bcdBootEntry."$propName" = $enumLine.Substring($propName.Length).TrimStart()
                    $lastPropName = $propName
                }
            }

            $bcdBootEntry.entryType = $bootEntryName

            if ((-not $All) -and ($bootEntryName -eq 'Windows Boot Manager'))
            {
                continue
            }

            $bcdBootEntry | ConvertTo-Json -Depth 32 | ConvertFrom-Json
        }
    }
}

function Copy-WindowsBootRecord
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Source,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Description,

        [Parameter()]
        [string]$StorePath
    )

    $bcdeditArgs = @()
    
    if ($StorePath)
    {
        $bcdeditArgs += '/store "{0}"' -f $StorePath
    }

    $bcdeditArgs += '/copy "{0}"' -f $Source
    $bcdeditArgs += '/d "{0}"' -f $Description

    $stopParseSymbol = '--%'
    $execResult = bcdedit.exe $stopParseSymbol ($bcdeditArgs -join ' ')

    if ($execResult -like 'The entry was successfully copied to*')
    {
        $newEntryId = $execResult.Substring('The entry was successfully copied to'.Length).TrimStart().TrimEnd('.')
        if ($StorePath)
        {
            Get-WindowsBootRecord -StorePath $StorePath | where { $_.Identifier -eq $newEntryId }
        }
        else
        {
            Get-WindowsBootRecord -Online | where { $_.Identifier -eq $newEntryId }
        }
    }
    else
    {
        throw $execResult
    }
}

function Remove-WindowsBootRecord
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Identifier,

        [Parameter()]
        [string]$StorePath,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$Cleanup = $true
    )

    $bcdeditArgs = @()
    $bcdeditArgs += '/delete {0}' -f $Identifier

    if ($Force)
    {
        $bcdeditArgs += '/f'
    }

    if ($Cleanup -eq $false)
    {
        $bcdeditArgs += '/nocleanup'
    }

    if ($StorePath)
    {
        $bcdeditArgs += '/store "{0}"' -f $StorePath
    }

    $stopParseSymbol = '--%'
    $execResult = bcdedit.exe $stopParseSymbol ($bcdeditArgs -join ' ')

    if ($execResult -ne 'The operation completed successfully.')
    {
        throw $execResult
    }
}

function Set-WindowsBootRecord
{
    [CmdletBinding(DefaultParameterSetName = 'PropertyValueSet')]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Identifier,

        [Parameter()]
        [string]$StorePath,

        [Parameter(Mandatory)]
        [string]$Property,

        [Parameter(Mandatory, ParameterSetName = 'RemovePropertySet')]
        [Parameter(Mandatory, ParameterSetName = 'RemoveListSet')]
        [switch]$Remove,

        [Parameter(Mandatory, ParameterSetName = 'PropertyValueSet')]
        [Parameter(Mandatory, ParameterSetName = 'RemoveListSet')]
        [Parameter(Mandatory, ParameterSetName = 'AppendListSet')]
        [Parameter(Mandatory, ParameterSetName = 'PrependListSet')]
        [string]$Value,

        [Parameter(Mandatory, ParameterSetName = 'AppendListSet')]
        [switch]$Append,

        [Parameter(Mandatory, ParameterSetName = 'PrependListSet')]
        [switch]$Prepend 
    )

    # bcdedit [/store <filename>] /set [{<id>}] <datatype> <value> [ /addfirst | /addlast | /remove ]

    $bcdeditArgs = @()

    if ($StorePath)
    {
        $bcdeditArgs += '/store "{0}"' -f $StorePath
    }

    if ($PSCmdlet.ParameterSetName -eq 'RemovePropertySet')
    {
        $bcdeditArgs += '/deletevalue {0}' -f $Identifier
        $bcdeditArgs += $Property
    }
    else
    {
        $bcdeditArgs += '/set {0}' -f $Identifier
        $bcdeditArgs += $Property
        $bcdeditArgs += $Value

        if ($PSCmdlet.ParameterSetName -eq 'AppendList')
        {
            $bcdeditArgs += '/addlast'
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'PrependList')
        {
            $bcdeditArgs += '/addfirst'
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'RemoveList')
        {
            $bcdeditArgs += '/remove'
        }
    }

    $stopParseSymbol = '--%'
    $execResult = bcdedit.exe $stopParseSymbol ($bcdeditArgs -join ' ')

    if ($execResult -ne 'The operation completed successfully.')
    {
        throw $execResult
    }
}

function Set-WindowsBootOrder
{
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]$Default,

        [Parameter()]
        [string[]]$DisplayOrder,

        [Parameter()]
        [string[]]$BootSequence
    )

    $stopParseSymbol = '--%'

    if ($Default)
    {
        # bcdedit /default {cbd971bf-b7b8-4885-951a-fa03044f5d71}
        $bcdeditArgs = @()
        $bcdeditArgs += '/default {0}' -f $Default
        $execResult = bcdedit.exe $stopParseSymbol ($bcdeditArgs -join ' ')

        if ($execResult -ne 'The operation completed successfully.')
        {
            throw $execResult
        }
    }

    if ($DisplayOrder)
    {
        # bcdedit /displayorder [id1] [id2] ...
        $bcdeditArgs = @()
        $bcdeditArgs += '/displayorder {0}' -f ($DisplayOrder -join ' ')
        $execResult = bcdedit.exe $stopParseSymbol ($bcdeditArgs -join ' ')

        if ($execResult -ne 'The operation completed successfully.')
        {
            throw $execResult
        }
    }

    if ($BootSequence)
    {
        # bcdedit /bootsequence [id1] [id2] ...
        $bcdeditArgs = @()
        $bcdeditArgs += '/bootsequence {0}' -f ($BootSequence -join ' ')
        $execResult = bcdedit.exe $stopParseSymbol ($bcdeditArgs -join ' ')

        if ($execResult -ne 'The operation completed successfully.')
        {
            throw $execResult
        }
    }
}