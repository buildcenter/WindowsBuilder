<#
    This script runs just before the user logs off.

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
		Message = 'User has signed out. Beginning logout tasks.'
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

    WriteToWindowsLog WindowsLogoutScriptBegin -Data "$env:USERDOMAIN\$env:USERNAME"

    # --- BEGIN CUSTOM SCRIPT ---


    # --- END CUSTOM SCRIPT ---
}
catch
{
    WriteToWindowsLog WindowsLogoutScriptError -Data ($_ | Out-String)
    $hasError = $true
}
finally
{
    if ($hasError)
    {
        WriteToWindowsLog WindowsLogoutScriptEndWithError
    }
    else
    {
        WriteToWindowsLog WindowsLogoutScriptEnd
    }
}
