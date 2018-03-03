<#
    This script runs after Windows begins shutting down.

    Add custom log messages after 'Begin custom log messages'.
    Script tasks goes after '--- BEGIN CUSTOM SCRIPT ---'
    Scripts will be executed with administrative privileges.
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

    # Startup/shutdown

	'WindowsStartupScriptBegin' = @{
		Category = 3000
		EntryType = 'Information'
		LogName = 'Host Access'
		Source = 'Startup'
		Message = 'Windows has started. Beginning startup tasks.'
		EventID = 10030
	}
	'WindowsStartupScriptEnd' = @{
		Category = 3000
		EntryType = 'Information'
		LogName = 'Host Access'
		Source = 'Startup'
		Message = 'Executed all Windows startup tasks.'
		EventID = 10035	
	}
	'WindowsStartupScriptEndWithError' = @{
		Category = 3000
		EntryType = 'Warning'
		LogName = 'Host Access'
		Source = 'Startup'
		Message = 'An error has occured while executing Windows startup tasks. Not all tasks are completed successfully.'
		EventID = 10036
	}
    'WindowsStartupScriptError' = @{
		Category = 3000
		EntryType = 'Error'
		LogName = 'Host Access'
		Source = 'Startup'
		Message = 'Startup task error: {0}'
		EventID = 10037
    }

	'WindowsShutdownScriptBegin' = @{
		Category = 3000
		EntryType = 'Information'
		LogName = 'Host Access'
		Source = 'Shutdown'
		Message = 'Windows is shutting down. Beginning shutdown tasks.'
		EventID = 10040
	}
	'WindowsShutdownScriptEnd' = @{
		Category = 3000
		EntryType = 'Information'
		LogName = 'Host Access'
		Source = 'Shutdown'
		Message = 'Executed all Windows shutdown tasks.'
		EventID = 10045	
	}
	'WindowsShutdownScriptEndWithError' = @{
		Category = 3000
		EntryType = 'Warning'
		LogName = 'Host Access'
		Source = 'Shutdown'
		Message = 'An error has occured while executing Windows shutdown tasks. Not all tasks are completed successfully.'
		EventID = 10046
	}
    'WindowsShutdownScriptError' = @{
		Category = 3000
		EntryType = 'Error'
		LogName = 'Host Access'
		Source = 'Shutdown'
		Message = 'Shutdown task error: {0}'
		EventID = 10047
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

    WriteToWindowsLog WindowsShutdownScriptBegin

    # --- BEGIN CUSTOM SCRIPT ---


    # --- END CUSTOM SCRIPT ---
}
catch
{
    WriteToWindowsLog WindowsShutdownScriptError -Data ($_ | Out-String)
    $hasError = $true
}
finally
{
    if ($hasError)
    {
        WriteToWindowsLog WindowsShutdownScriptEndWithError
    }
    else
    {
        WriteToWindowsLog WindowsShutdownScriptEnd
    }
}
