<#
    This script runs after a user logs on.

    Add custom log messages after 'Begin custom log messages'.
    Script tasks goes after '--- BEGIN CUSTOM SCRIPT ---'
    Scripts will be executed with user privileges.
#>

# Global preference
$ErrorActionPreference = 'Stop'

$disableLogging = $false
$disableApplicationLogging = $false
$hasError = $false

$logName = 'Host Access'
$logSource = @('Startup', 'Shutdown', 'Logon', 'Logout', 'UserOOBE')

$logEnum = @{
	'FailedToCreateHostAccessLog' = @{
		Category = 100
		EntryType = 'Error'
		Source = 'Application Error'
		LogName = 'Application'
		Message = 'Unable to create log file "Host Access": {0}'
        EventID = 0
	}
	'FailedToGetHostAccessLog' = @{
		Category = 100
		EntryType = 'Error'
		Source = 'Application Error'
		LogName = 'Application'
		Message = 'An unknown error has occured while attempting to retrieve the log file "Host Access".'
        EventID = 0
	}
	'HostAccessLogNameAmbiguous' = @{
		Category = 100
		EntryType = 'Error'
		Source = 'Application Error'
		LogName = 'Application'
		Message = 'Unable to retrieve log file because the name "Host Access" is ambiguous.'
        EventID = 0
	}
	'WriteHostAccessLogError' = @{
		Category = 100
		EntryType = 'Error'
		Source = 'Application Error'
		LogName = 'Application'
		Message = 'An error has occured while writing to log "Host Access". Further writes to this log will be lost.'
        EventID = 0
	}
    'CreatingHostAccessLog' = @{
		Category = 100
		EntryType = 'Warning'
		Source = 'Application'
		LogName = 'Application'
	    Message = 'The log file "Host Access" does not exist. Creating it now.'
        EventID = 0
    }

    # Logon/logoff

	'WindowsLogonScriptBegin' = @{
		Category = 3000
		EntryType = 'Information'
		LogName = 'Host Access'
		Source = 'Logon'
		Message = 'User "{0}" has signed in. Beginning logon tasks.'
		EventID = 10060
	}
	'WindowsLogonScriptEnd' = @{
		Category = 3000
		EntryType = 'Information'
		LogName = 'Host Access'
		Source = 'Logon'
		Message = 'Executed all Windows logon tasks.'
		EventID = 10065	
	}
	'WindowsLogonScriptEndWithError' = @{
		Category = 3000
		EntryType = 'Warning'
		LogName = 'Host Access'
		Source = 'Logon'
		Message = 'An error has occured while executing Windows logon tasks. Not all tasks are completed successfully.'
		EventID = 10066
	}
    'WindowsLogonScriptError' = @{
		Category = 3000
		EntryType = 'Error'
		LogName = 'Host Access'
		Source = 'Logon'
		Message = 'Logon task error: {0}'
		EventID = 10067
    }

	'WindowsLogoutScriptBegin' = @{
		Category = 3000
		EntryType = 'Information'
		LogName = 'Host Access'
		Source = 'Logout'
		Message = 'User "{0}" has signed out. Beginning logout tasks.'
		EventID = 10070
	}
	'WindowsLogoutScriptEnd' = @{
		Category = 3000
		EntryType = 'Information'
		LogName = 'Host Access'
		Source = 'Logout'
		Message = 'Executed all Windows logout tasks.'
		EventID = 10075	
	}
	'WindowsLogoutScriptEndWithError' = @{
		Category = 3000
		EntryType = 'Warning'
		LogName = 'Host Access'
		Source = 'Logout'
		Message = 'An error has occured while executing Windows logout tasks. Not all tasks are completed successfully.'
		EventID = 10076
	}
    'WindowsLogoutScriptError' = @{
		Category = 3000
		EntryType = 'Error'
		LogName = 'Host Access'
		Source = 'Logout'
		Message = 'Logout task error: {0}'
		EventID = 10077
    }
}

function WriteToWindowsLog
{
	Param(
		[Parameter(Mandatory, Position = 1)]
		[string]$MessageID,

        [Parameter()]
        [string[]]$Data
	)

    $writeLogParams = $logEnum."$MessageID"

    if (($writeLogParams.LogName -eq 'Application') -and ($disableApplicationLogging -eq $true))
    {
        return
    }
    elseif (($writeLogParams.LogName -ne 'Application') -and ($disableLogging -eq $true))
    {
        return
    }

    if ($Data)
    {
        $writeLogParams.Message = $writeLogParams.Message -f $Data
    }

    try
    {
        Write-EventLog @writeLogParams
    }
    catch
    {
        if ($writeLogParams.LogName -eq 'Application')
        {
            Set-Variable -Name disableApplicationLogging -Value $true -Scope 1 -Force
        }
        else
        {
            WriteToWindowsLog WriteHostAccessLogError
            Set-Variable -Name disableLogging -Value $true -Scope 1 -Force
        }
    }
}

try
{
    $logEnum += @{
        # Begin custom log messages

        'UserOobeStart' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Starting user OOBE'
		    EventID = 13010	
        }
        'UserOobeEnd' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'User OOBE has completed'
		    EventID = 13015	
        }
        'ReadOemCustomAnswerFile' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Reading OEM customization answer file'
		    EventID = 13020	
        }
        'ReadOemCustomAnswerFileFailed' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Failed to read OEM customization answer file. The file may be corrupted.'
		    EventID = 13021	
        }
        'OemCustomAnswerFileNotFound' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'The OEM customization answer file does not exist'
		    EventID = 13022
        }
        'RemovingOobeFlag' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Removing user OOBE flag'
		    EventID = 13023	
        }
        'EnableColorTitlebar' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Enabling colored title bar'
		    EventID = 13030	
        }
        'SetSoundSchemeStart' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Setting sound scheme'
		    EventID = 13040
        }
        'SetSoundSchemeEnd' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Setting sound scheme'
		    EventID = 13041
        }
        'SetSoundScheme' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Set app sound event "{0}": "{1}" -> "{2}"'
		    EventID = 13045
        }
        'SetCursorScheme' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Setting cursor scheme'
		    EventID = 13050
        }
        'RefreshCursorScheme' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Refreshing system cursor now'
		    EventID = 13051
        }
        'ReadUserLocale' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Reading current user locale'
		    EventID = 13060
        }
        'CustomizeEnUSLocaleStart' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'The user locale is "en-US". Starting customization.'
		    EventID = 13061
        }
        'CustomizeEnUSLocaleEnd' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Customization of user locale "en-US" has completed'
		    EventID = 13062
        }
        'SkipCustomizeNonEnUSLocale' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Skipped user locale customization because the user locale is not "en-US"'
		    EventID = 13063
        }
        'CustomizeEnUSLocale' = @{
		    Category = 3100
		    EntryType = 'Information'
		    LogName = 'Host Access'
		    Source = 'UserOOBE'
		    Message = 'Set user locale property "{0}" to "{1}"'
		    EventID = 13065
        }
    }

    $log = Get-EventLog -List | where { $_.Log -eq $logName }

    if (-not $log)
    {
        WriteToWindowsLog FailedToGetHostAccessLog
    }
    elseif ($log.Count -gt 1)
    {
        WriteToWindowsLog HostAccessLogNameAmbiguous
    }

    # -------------------------------------------------------------

    WriteToWindowsLog WindowsLogonScriptBegin -Data "$env:USERDOMAIN\$env:USERNAME"

    # --- BEGIN CUSTOM SCRIPT ---

    $runUserOobeConfig = $false
    if (Test-Path (Join-Path $env:USERPROFILE -ChildPath 'oobeinit.flag') -PathType Leaf)
    {
        $oemDataFile = Join-Path $env:windir -ChildPath 'Setup\Scripts\oemcustom.json'
        if (Test-Path $oemDataFile -PathType Leaf)
        {
            WriteToWindowsLog ReadOemCustomAnswerFile
            try
            {
    	        $oemdata = ConvertFrom-Json ((Get-Content -Path $oemDataFile) -join [Environment]::NewLine)
                $runUserOobeConfig = $true
            }
            catch
            {
                WriteToWindowsLog ReadOemCustomAnswerFileFailed
                $runUserOobeConfig = $false
            }
        }
        else
        {
            WriteToWindowsLog OemCustomAnswerFileNotFound
        }

        WriteToWindowsLog RemovingOobeFlag
        del (Join-Path $env:USERPROFILE -ChildPath 'oobeinit.flag') -Force
    }

    if ($runUserOobeConfig -eq $true)
    {
        WriteToWindowsLog UserOobeStart

        if ($oemdata.enableColorTitlebar -eq $true)
        {
            WriteToWindowsLog EnableColorTitlebar
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name ColorPrevalence -Value 1
        }

        if ($oemdata.soundTheme -and ($oemdata.soundTheme -is [string]))
        {
            WriteToWindowsLog SetSoundSchemeStart

            Set-ItemProperty -Path 'HKCU:\AppEvents\Schemes' -Name '(Default)' -Value $oemdata.soundTheme

            dir 'HKCU:\AppEvents\Schemes\Apps' | select -expand PSChildName | ForEach-Object {
                $appName = $_
                $soundAppPath = Join-Path 'HKCU:\AppEvents\Schemes\Apps' -ChildPath $appName

                dir $soundAppPath | select -expand PSChildName | ForEach-Object {
                    $appEventName = $_
                    $appEventPath = Join-Path $soundAppPath -ChildPath $appEventName
                    $currentSchemePath = Join-Path $appEventPath -ChildPath '.Current'
                    $customSchemePath = Join-Path $appEventPath -ChildPath $oemdata.soundTheme

                    if (Test-Path $customSchemePath)
                    {
                        if (-not (Test-Path $currentSchemePath))
                        {
                            md $currentSchemePath -Force | Out-Null
                        }

                        $schemeValue = Get-ItemProperty -Path $customSchemePath -Name '(Default)' | select -expand '(Default)'
                        $currentValue = Get-ItemProperty -Path $currentSchemePath -Name '(Default)' | select -expand '(Default)'
                        Set-ItemProperty -Path $currentSchemePath -Name '(Default)' -Value $schemeValue
                    }
                }
            }

            WriteToWindowsLog SetSoundSchemeEnd
        }

        WriteToWindowsLog ReadUserLocale
        $userLocale = Get-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'LocaleName' | select -expand LocaleName
        if ($userLocale -eq 'en-US')
        {
            WriteToWindowsLog CustomizeEnUSLocaleStart

            @(
                'sLongDate', 'sShortDate', 'iDate', 'iFirstDayOfWeek'
                'iMeasure', 'iPaperSize'
            ) | ForEach-Object {
                if ($oemdata.defaultLocale."$_" -and ($oemdata.defaultLocale."$_" -is [string]))
                {
        	        Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name $_ -Value $oemdata.defaultLocale."$_"
                }
            }

            WriteToWindowsLog CustomizeEnUSLocaleEnd
        }
        else
        {
            WriteToWindowsLog SkipCustomizeNonEnUSLocale
        }

        WriteToWindowsLog SetCursorScheme
        $defaultCursorScheme = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\Cursors\Default'
        $defaultCursorScheme | Get-Member -MemberType NoteProperty | where { 
	        $_.Name -notin @('Scheme Source', 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider') 
        } | ForEach-Object {
	        Set-ItemProperty -Path 'HKCU:\Control Panel\Cursors' -Name $_.Name -Value $defaultCursorScheme."$($_.Name)"
        }

        WriteToWindowsLog RefreshCursorScheme

        $cursorRefresh = Add-Type -Name WinAPICall -Namespace SystemParamInfo -PassThru -MemberDefinition (@(
            '[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]'
            'public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);'
        ) -join [Environment]::NewLine)

        $cursorRefresh::SystemParametersInfo(0x0057, 0, $null, 0)

        WriteToWindowsLog UserOobeEnd
    }

    # --- END CUSTOM SCRIPT ---
}
catch
{
    WriteToWindowsLog WindowsLogonScriptError -Data ($_ | Out-String)
    $hasError = $true
}
finally
{
    if ($hasError)
    {
        WriteToWindowsLog WindowsLogonScriptEndWithError
    }
    else
    {
        WriteToWindowsLog WindowsLogonScriptEnd
    }
}
