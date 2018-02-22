<#
    .SYNOPSIS
        This is a helper script for running Builder without importing the module.

    .EXAMPLE
        .\builder.ps1 "buildscript.ps1" "BuildHelloWord" "netfx462" 

        DESCRIPTION
        -----------
        You need to match parameter definitions for Builder.psm1/Invoke-Builder. Otherwise named parameter binding fails.
#>
[CmdletBinding()]
Param(
    [Parameter(Position = 1, Mandatory = $false)]
    [string]$BuildFile,

    [Parameter(Mandatory = $false, Position = 2)]
    [string[]]$TaskList = @(),

    [Parameter(Mandatory = $false)]
    [switch]$Docs,

    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{},

    [Parameter(Mandatory = $false)]
    [hashtable]$Properties = @{},

    [Parameter(Mandatory = $false)]
    [Alias("Init")]
    [scriptblock]$Initialization = {},

    [Parameter(Mandatory = $false)]
    [switch]$NoLogo,

    [Parameter(Mandatory = $false)]
    [switch]$Help,

    [Parameter(Mandatory = $false)]
    [string]$ScriptPath,

    [Parameter(Mandatory = $false)]
    [switch]$DetailDocs,

    [Parameter(Mandatory = $false)]
    [switch]$TimeReport
)

# setting $scriptPath here, not as default argument, to support calling as "powershell -File Builder.ps1"
if (-not $ScriptPath) 
{
    $ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
}

# '[B]uilder' is the same as 'builder' but $Error is not polluted
Remove-Module [B]uilder
Import-Module (Join-Path $ScriptPath -ChildPath 'Builder.psm1') -Verbose:$false
if ($Help) 
{
    Get-Help Invoke-Builder -Full
    return
}

if ($BuildFile -and (-not (Test-Path $BuildFile -PathType Leaf))) 
{
    $buildFileFullPath = Join-Path $ScriptPath -ChildPath $BuildFile
    if (Test-Path $buildFileFullPath -PathType Leaf) 
    {
        $BuildFile = $buildFileFullPath
    }
} 

$buildParams = @{
    'BuildFile' = $BuildFile
    'TaskList' = $TaskList
    'Docs' = $Docs
    'Parameters' = $Parameters
    'Properties' = $Properties
    'Initialization' = $Initialization
    'NoLogo' = $NoLogo
    'DetailDocs' = $DetailDocs
    'TimeReport' = $TimeReport
}
Invoke-Builder @buildParams
