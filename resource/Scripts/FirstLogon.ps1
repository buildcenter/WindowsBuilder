$logTimestampFormat = 'yyyy-MM-dd@hh:mm:ss'
$logPath = 'C:\Windows\oobefl.log'

('[{0}] Reduce autologon count to 0' -f (Get-Date -Format $logTimestampFormat)) | Add-Content -Path $logPath
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 0

$oemDataFile = Join-Path $env:windir -ChildPath 'Setup\Scripts\oemcustom.json'
if (Test-Path $oemDataFile -PathType Leaf)
{
    ('[{0}] Running OOBE.' -f (Get-Date -Format $logTimestampFormat)) | Add-Content -Path $logPath

    try
    {
        $oemdata = ConvertFrom-Json ((Get-Content -Path $oemDataFile) -join [Environment]::NewLine)
    }
    catch
    {
        ('[{0}] OOBE custom file is corrupted.' -f (Get-Date -Format $logTimestampFormat)) | Add-Content -Path $logPath
    }

    if ($oemdata)
    {
        if ($oemdata.enableColorTitlebar -eq $true)
        {
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name ColorPrevalence -Value 1
        }        

        if ($oemdata.soundTheme -and ($oemdata.soundTheme -is [string]))
        {
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
                        Set-ItemProperty -Path $currentSchemePath -Name '(Default)' -Value $schemeValue
                    }
                }
            }
        }

        $userLocale = Get-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'LocaleName' | select -expand LocaleName
        if ($userLocale -eq 'en-US')
        {
            @(
                'sLongDate', 'sShortDate', 'iDate', 'iFirstDayOfWeek'
                'iMeasure', 'iPaperSize'
            ) | ForEach-Object {
                if ($oemdata.defaultLocale."$_" -and ($oemdata.defaultLocale."$_" -is [string]))
                {
        	        Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name $_ -Value $oemdata.defaultLocale."$_"
                }
            }
        }

        $defaultCursorScheme = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\Cursors\Default'
        $defaultCursorScheme | Get-Member -MemberType NoteProperty | where { 
	        $_.Name -notin @('Scheme Source', 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider') 
        } | ForEach-Object {
	        Set-ItemProperty -Path 'HKCU:\Control Panel\Cursors' -Name $_.Name -Value $defaultCursorScheme."$($_.Name)"
        }

        $cursorRefresh = Add-Type -Name WinAPICall -Namespace SystemParamInfo -PassThru -MemberDefinition (@(
            '[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]'
            'public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);'
        ) -join [Environment]::NewLine)

        $cursorRefresh::SystemParametersInfo(0x0057, 0, $null, 0)
    }
}

('[{0}] All done. Rebooting now.' -f (Get-Date -Format $logTimestampFormat)) | Add-Content -Path $logPath
Restart-Computer -Force
