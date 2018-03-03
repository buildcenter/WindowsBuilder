$defaultJsonConfig = ConvertFrom-Json @'
{
    "disableRemoteAssist": true,
    "soundTheme": "Persona",
    "enableColorTitlebar": true,
    "defaultLocale": {
        "sLongDate": "dddd, d MMMM, yyyy",
        "sShortDate": "d/M/yyyy",
        "iDate": "1",
        "iFirstDayOfWeek": "0",
        "iMeasure": "0",
        "iPaperSize": "9"
    },
    "timezone": "GMT Standard Time",
    "ime": "en-US;zh-CN"
}
'@

if (-not (Test-Path "$PSScriptRoot\unattend.xml.tmpl"))
{
    throw "A required file does not exist."
}

$xmlTemplate = (Get-Content -Path "$PSScriptRoot\unattend.xml.tmpl") -join [Environment]::NewLine

if (Test-Path "$PSScriptRoot\oemcustom-ref.json")
{
    $customJsonConfig = ConvertFrom-Json ((Get-Content -Path "$PSScriptRoot\oemcustom-ref.json") -join [Environment]::NewLine)
}

$effectiveJsonConfig = @{}

$defaultJsonConfig | Get-Member -MemberType NoteProperty | select -expand Name | ForEach-Object {
    if ($defaultJsonConfig."$_" -is [psobject])
    {
        $propName = $_
        $effectiveJsonConfig."$propName" = @{}

        $defaultJsonConfig."$propName" | Get-Member -MemberType NoteProperty | select -expand Name | ForEach-Object {
            if ($customJsonConfig."$propName"."$_")
            {
                $effectiveJsonConfig."$propName"."$_" = $customJsonConfig."$propName"."$_"
            }
            else
            {
                $effectiveJsonConfig."$propName"."$_" = $defaultJsonConfig."$propName"."$_"
            }
        }
    }
    else
    {
        if ($customJsonConfig."$_")
        {
            $effectiveJsonConfig."$_" = $customJsonConfig."$_"
        }
        else
        {
            $effectiveJsonConfig."$_" = $defaultJsonConfig."$_"
        }
    }
}

if ($customJsonConfig)
{
	$customJsonConfig | Get-Member -MemberType NoteProperty | select -expand Name | ForEach-Object {
	    if (-not $effectiveJsonConfig.ContainsKey($_))
	    {
                if ($customJsonConfig."$_" -is [psobject])
                {
	            $effectiveJsonConfig."$_" = @{}
                    $propName = $_
                    $customJsonConfig."$_" | Get-Member -MemberType NoteProperty | select -expand name | ForEach-Object {
                        $effectiveJsonConfig."$propName"."$_" = $customJsonConfig."$propName"."$_"
                    }
                }
                else
                {
	            $effectiveJsonConfig."$_" = $customJsonConfig."$_"
                }
	    }
	}
}

$mandatoryProps = @(
    'userName'
    'superuserPassword'
    'computerName'
    'organizationName'
)
$mandatoryProps | ForEach-Object {
    if (-not $effectiveJsonConfig.ContainsKey($_))
    {
        $effectiveJsonConfig."$_" = Read-Host "Enter value for property '$_'"
    }
}

if (-not $effectiveJsonConfig.ContainsKey('userPassword'))
{
    $effectiveJsonConfig.userPassword = ((((@(97..122) | Get-Random -Count 6)) | % { [char]$_ }) -join '') + ((((@(0..9) | Get-Random -Count 2)) | % { $_ }) -join '')
}

if (-not $effectiveJsonConfig.ContainsKey('friendPassword'))
{
    $effectiveJsonConfig.friendPassword = ((((@(97..122) | Get-Random -Count 6)) | % { [char]$_ }) -join '') + ((((@(0..9) | Get-Random -Count 2)) | % { $_ }) -join '')
}

if (-not $effectiveJsonConfig.ContainsKey('superuserName'))
{
    $effectiveJsonConfig.superuserName = 'Super{0}' -f $effectiveJsonConfig.userName
}

if (-not $effectiveJsonConfig.ContainsKey('superuserFullName'))
{
    $effectiveJsonConfig.superuserFullName = 'Super {0}' -f $effectiveJsonConfig.userName
}

if (-not $effectiveJsonConfig.ContainsKey('userFullName'))
{
    $effectiveJsonConfig.userFullName = $effectiveJsonConfig.userName
}

if (-not $effectiveJsonConfig.ContainsKey('accentColor'))
{
    $effectiveJsonConfig.accentColor = @(
        '0x00be0015'
        '0x00e64000'
        '0x00f8c602'
        '0x00009a26'
        '0x007195a7'
        '0x0052260b'
        '0x00603c53'
        '0x00fe386e'
        '0x00cc292a'
    ) | Get-Random
}

if (-not $effectiveJsonConfig.ContainsKey('computerDescription'))
{
    $effectiveJsonConfig.computerDescription = 'PC of {0}' -f $effectiveJsonConfig.userFullName
}

if (-not $effectiveJsonConfig.ContainsKey('autoLicenseAcceptance'))
{
    $effectiveJsonConfig.autoLicenseAcceptance = 'false'
}

$effectiveJsonConfig.Keys | ForEach-Object {
    if (($effectiveJsonConfig."$_" -isnot [hashtable]) -and 
    	($effectiveJsonConfig."$_" -isnot [array]))
    {
        $xmlTemplate = $xmlTemplate.Replace('{{ $' + $_ + ' }}', $effectiveJsonConfig."$_")
    }
}

$xmlTemplate | Set-Content -Path "$PSScriptRoot\unattend.xml" -Encoding UTF8

@('superuserPassword', 'userPassword', 'friendPassword') | ForEach-Object {
	$effectiveJsonConfig.Remove($_)	
}

$effectiveJsonConfig | ConvertTo-Json | Set-Content -Path "$PSScriptRoot\oemcustom.json" -Encoding UTF8
