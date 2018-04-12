#Requires -Version 2.0

#######################################################################
#  Localization data
#######################################################################

# Ignore error if localization for current UICulture is unavailable
Import-LocalizedData -BindingVariable PBLocalizedData -BaseDirectory $PSScriptRoot -FileName 'Message.psd1' -ErrorAction $(
    if ($PSVersionTable.PSVersion.Major -ge 3) { 'Ignore' } 
    else { 'SilentlyContinue' }
)

# Fallback to US English if localization data failed to load
# Do not continue if fallback failed to load too
if (-not $PBLocalizedData)
{
    Import-LocalizedData -BindingVariable PBLocalizedData -BaseDirectory $PSScriptRoot -UICulture 'en-US' -FileName 'Message.psd1' -ErrorVariable loadDefaultLocalizationError -ErrorAction $(
        if ($PSVersionTable.PSVersion.Major -ge 3) { 'Ignore' } 
        else { 'SilentlyContinue' }
    )

    # Continue with error if localization variable is available
    # Otherwise stop
    if ($loadDefaultLocalizationError)
    {
        if (-not $PBLocalizedData)
        {
            $PSCmdlet.ThrowTerminatingError($loadDefaultLocalizationError[0])            
        }
        else
        {
            $loadDefaultLocalizationError[0]
        }
    }
}

# This shouldn't happen. Just in case.
if (-not $PBLocalizedData)
{
    if (-not (Test-Path (Join-Path $PSScriptRoot -ChildPath 'en-US/Message.psd1') -PathType Leaf))
    {
        # This will generate the ItemNotFound exception
        Get-Content (Join-Path $PSScriptRoot -ChildPath 'en-US/Message.psd1') -ErrorVariable localizationFileNotFoundError -ErrorAction $(
            if ($PSVersionTable.PSVersion.Major -ge 3) { 'Ignore' } 
            else { 'SilentlyContinue' }
        )

        $localizationException = $localizationFileNotFoundError[0].Exception
        if (-not $localizationException)
        {
            # This shouldn't happen, but just in case
            $localizationException = "Cannot find path '{0}' because it does not exist." -f (Join-Path $PSScriptRoot -ChildPath 'en-US/Message.psd1')
        }

        $PSCmdlet.ThrowTerminatingError((
            New-Object 'System.Management.Automation.ErrorRecord' -ArgumentList $localizationException, 'DefaultLocalizationFileNotFound', 'ObjectNotFound', $null
        ))        
    }
    else
    {
        $localizationError = New-Object 'System.Management.Automation.ErrorRecord' -ArgumentList ("An error has occured while loading the '{0}' localization data file." -f (Join-Path $PSScriptRoot -ChildPath 'en-US/Message.psd1')), 'InvalidLocalizationFile', 'InvalidData', $null
        $PSCmdlet.ThrowTerminatingError($localizationError)
    }
}


#######################################################################
#  Public module functions
#######################################################################

function Exec
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$Command,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = ($PBLocalizedData.Err_BadCommand -f $Command),

        [Parameter(Mandatory = $false)]
        [int]$MaxRetry = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [Int]::MaxValue)]
        [int]$RetryDelay = 1,
        
        [Parameter(Mandatory = $false)]
        [string]$RetryTriggerErrorPattern = $null,

        [Parameter(Mandatory = $false)]
        [switch]$NoWill
    )

    $tryCount = 1

    do 
    {
        try 
        {
            $global:LASTEXITCODE = 0
            & $Command

            if ($LASTEXITCODE -ne 0) 
            {
                Die $ErrorMessage 'ExecError' -NoWill:$NoWill
            }

            break
        }
        catch [Exception]
        {
            if ($tryCount -gt $MaxRetry) 
            {
                Die $_ 'ExecError' -NoWill:$NoWill
            }

            if ($RetryTriggerErrorPattern -ne $null) 
            {
                $isMatch = [RegEx]::IsMatch($_.Exception.Message, $RetryTriggerErrorPattern)

                if ($isMatch -eq $false) 
                { 
                    Die $_ 'ExecError' -NoWill:$NoWill
                }
            }

            Write-Output ("[EXEC] " + ($PBLocalizedData.RetryMessage -f $tryCount, $MaxRetry, $RetryDelay))

            $tryCount++
            Start-Sleep -Seconds $RetryDelay
        }
    } while ($true)
}

function Assert
{
    # .EXTERNALHELP Builder-Help.xml
    
    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        $Condition,

        [Parameter(Position = 2, Mandatory = $true)]
        $ErrorMessage,

        [Parameter()]
        [switch]$NoWill
    )

    if (-not $Condition) 
    {
        Die $ErrorMessage 'AssertConditionFailure' -NoWill:$NoWill
    }
}

function Properties 
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $BuildEnv.Context.Peek().Properties += $ScriptBlock
}

function Will
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $BuildEnv.Context.Peek().Will += $ScriptBlock
}

function PrintTask 
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        $Format
    )

    $BuildEnv.Context.Peek().Setting.TaskNameFormat = $Format
}

function Include 
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [string]$FilePath
    )

    Assert (Test-Path $FilePath -PathType Leaf) -ErrorMessage ($PBLocalizedData.Err_InvalidIncludePath -f $FilePath)
    $BuildEnv.Context.Peek().Includes.Enqueue((Resolve-Path $FilePath))
}

function TaskSetup 
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $BuildEnv.Context.Peek().TaskSetupScriptBlock = $ScriptBlock
}

function TaskTearDown 
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $BuildEnv.Context.Peek().TaskTearDownScriptBlock = $ScriptBlock
}

function EnvPath 
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [string[]]$Path
    )

    $BuildEnv.Context.Peek().Setting.EnvPath = $Path
    ConfigureBuildEnvironment
}

function Invoke-Task
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$TaskName
    )

    Assert $TaskName ($PBLocalizedData.Err_InvalidTaskName)

    $taskKey = $TaskName.ToLower()

    if ($CurrentContext.Aliases.Contains($taskKey)) 
    {
        $TaskName = $CurrentContext.Aliases."$taskKey".Name
        $taskKey = $taskName.ToLower()
    }

    $CurrentContext = $BuildEnv.Context.Peek()

    Assert ($CurrentContext.Tasks.Contains($taskKey)) -ErrorMessage ($PBLocalizedData.Err_TaskNameDoesNotExist -f $TaskName)

    if ($CurrentContext.ExecutedTasks.Contains($taskKey)) 
    { 
        return 
    }

    Assert (-not $CurrentContext.CallStack.Contains($taskKey)) -ErrorMessage ($PBLocalizedData.Err_CircularReference -f $TaskName)

    $CurrentContext.CallStack.Push($taskKey)

    $task = $CurrentContext.Tasks.$taskKey

    $preconditionIsValid = & $task.Precondition

    if (-not $preconditionIsValid) 
    {
        WriteColoredOutput ($PBLocalizedData.PreconditionWasFalse -f $TaskName) -ForegroundColor Cyan
    } 
    else 
    {
        if ($taskKey -ne 'default') 
        {
            if ($task.PreAction -or $task.PostAction) 
            {
                Assert ($task.Action -ne $null) -ErrorMessage ($PBLocalizedData.Err_MissingActionParameter -f $TaskName)
            }

            if ($task.Action) 
            {
                try 
                {
                    foreach ($childTask in $task.DependsOn) 
                    {
                        Invoke-Task $childTask
                    }

                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    $CurrentContext.CurrentTaskName = $TaskName

                    & $CurrentContext.TaskSetupScriptBlock

                    if ($task.PreAction) 
                    {
                        & $task.PreAction
                    }

                    if ($CurrentContext.Setting.TaskNameFormat -is [scriptblock]) 
                    {
                        & $currentContext.Setting.TaskNameFormat $TaskName
                    } 
                    else 
                    {
                        WriteColoredOutput ($CurrentContext.Setting.TaskNameFormat -f $TaskName) -ForegroundColor Cyan
                    }

                    foreach ($reqVar in $task.RequiredVariables) 
                    {
                        Assert ((Test-Path "Variable:$reqVar") -and ((Get-Variable $reqVar).Value -ne $null)) -ErrorMessage ($PBLocalizedData.RequiredVarNotSet -f $reqVar, $TaskName)
                    }

                    & $task.Action

                    if ($task.PostAction) 
                    {
                        & $task.PostAction
                    }

                    & $CurrentContext.TaskTearDownScriptBlock
                    $task.Duration = $stopwatch.Elapsed
                } 
                catch 
                {
                    if ($task.ContinueOnError) 
                    {
                        Write-Output $PBLocalizedData.Divider
                        WriteColoredOutput ($PBLocalizedData.ContinueOnError -f $TaskName, $_) -ForegroundColor Yellow
                        Write-Output $PBLocalizedData.Divider
                        $task.Duration = $stopwatch.Elapsed
                    }  
                    else 
                    {
                        WriteColoredOutput ($_ | Out-String) -ForegroundColor Red
                        Die '' 'InvokeTaskError' -NoWill
                    }
                }
            } 
            else 
            {
                # no action was specified but we still execute all the dependencies
                foreach ($childTask in $task.DependsOn) 
                {
                    Invoke-Task $childTask
                }
            }
        } 
        else 
        {
            foreach ($childTask in $task.DependsOn) 
            {
                Invoke-Task $childTask
            }
        }

        Assert (& $task.PostCondition) -ErrorMessage ($PBLocalizedData.PostconditionFailed -f $TaskName)
    }

    $poppedTaskKey = $CurrentContext.CallStack.Pop()
    Assert ($poppedTaskKey -eq $taskKey) -ErrorMessage ($PBLocalizedData.Err_CorruptCallStack -f $taskKey, $poppedTaskKey)

    $CurrentContext.ExecutedTasks.Push($taskKey)
}

function Task
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [string]$Name,

        [Parameter(Position = 2, Mandatory = $false)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $false)]
        [scriptblock]$PreAction,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$PostAction,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Precondition = { $true },

        [Parameter(Mandatory = $false)]
        [scriptblock]$Postcondition = { $true },

        [Parameter(Mandatory = $false)]
        [switch]$ContinueOnError,

        [Parameter(Mandatory = $false)]
        [string[]]$Depends = @(),
 
        [Parameter(Mandatory = $false)]
        [string[]]$RequiredVariables = @(),

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [string]$Alias
    )

    if ($Name -eq 'default') 
    {
        Assert (-not $Action) -ErrorMessage ($PBLocalizedData.Err_DefaultTaskCannotHaveAction)
    }

    $newTask = @{
        Name = $Name
        DependsOn = $Depends
        PreAction = $PreAction
        Action = $Action
        PostAction = $PostAction
        Precondition = $Precondition
        Postcondition = $Postcondition
        ContinueOnError = $ContinueOnError
        Description = $Description
        Duration = [System.TimeSpan]::Zero
        RequiredVariables = $RequiredVariables
        Alias = $Alias
    }

    $taskKey = $Name.ToLower()

    $CurrentContext = $BuildEnv.Context.Peek()

    Assert (-not $CurrentContext.Tasks.ContainsKey($taskKey)) -ErrorMessage ($PBLocalizedData.Err_DuplicateTaskName -f $Name)

    $CurrentContext.Tasks.$taskKey = $newTask

    if ($Alias)
    {
        $aliasKey = $Alias.ToLower()

        Assert (-not $CurrentContext.Aliases.ContainsKey($aliasKey)) -ErrorMessage ($PBLocalizedData.Err_DuplicateAliasName -f $Alias)

        $CurrentContext.Aliases.$aliasKey = $newTask
    }
}

function Say
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding(DefaultParameterSetName = 'NormalSet')]
    Param(
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'NormalSet')]
        [string]$Message,

        [Parameter(Mandatory = $true, ParameterSetName = 'DividerSet')]
        [switch]$Divider,

        [Parameter(Mandatory = $true, ParameterSetName = 'NewLineSet')]
        [switch]$NewLine,

        [Parameter(Mandatory = $false, ParameterSetName = 'NewLineSet')]
        [ValidateRange(1, [Int]::MaxValue)]
        [int]$LineCount = 1,

        [Parameter(Mandatory = $false, ParameterSetName = 'NormalSet')]
        [ValidateRange(0, 6)]
        [Alias('v')]
        [int]$VerboseLevel = 1,

        [Parameter(Mandatory = $false, ParameterSetName = 'NormalSet')]
        [Alias('fg')]
        [System.ConsoleColor]$ForegroundColor = 'Yellow',

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # configured verbose level = 0 --> no output except errors
    if ((-not $Force) -and ($BuildEnv.Context.Peek().Setting.VerboseLevel -eq 0))
    {
        return
    }

    # this works even if $Host is not around
    $dividerMaxLength = [Math]::Max(70, $Host.UI.RawUI.WindowSize.Width - 1)
 
    if ($PSCmdlet.ParameterSetName -eq 'DividerSet')
    {
        Write-Output ''
        WriteColoredOutput ('+' * $dividerMaxLength) -ForegroundColor Cyan
        Write-Output ''
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'NewLineSet')
    {
        for ($i = 0; $i -lt $LineCount; $i++)
        {
            Write-Output ''
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'NormalSet')
    {
        # suppress output if verbose level > configured verbose level
        if ((-not $Force) -and ($VerboseLevel -gt $BuildEnv.Context.Peek().Setting.VerboseLevel))
        {
            return
        }

        WriteColoredOutput $Message -ForegroundColor $(
            if ($VerboseLevel -eq 0) { 'Red' }
            elseif ($VerboseLevel -eq 1) { $ForegroundColor }
            elseif ($VerboseLevel -eq 2) { 'Green' }
            elseif ($VerboseLevel -eq 3) { 'Magenta' }            
            elseif ($VerboseLevel -eq 4) { 'DarkMagenta' }            
            else { 'Gray' }
        )
    }
}

function Die
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Message,

        [Parameter(Mandatory = $false, Position = 2)]
        [string]$ErrorCode = 'BuildError',

        [Parameter(Mandatory = $false)]
        [switch]$NoWill
    )

    if ($NoWill)
    {
        # Do no execute wills (if any) and die instantly
    }
    else
    {
        #$currentContext = $BuildEnv.Context.Peek()
        $currentTaskName = $CurrentContext.CallStack.Peek()

        if ($CurrentContext.Will)
        {
            foreach ($willBlock in $CurrentContext.Will)
            {
                . $willBlock $currentTaskName
            }
        }
    }

    if ($Message -eq '') 
    { 
        $Message = $PBLocalizedData.UnknownError 
    }

    $errRecord = New-Object 'System.Management.Automation.ErrorRecord' -ArgumentList $Message, $ErrorCode, 'InvalidOperation', $null
    $PSCmdlet.ThrowTerminatingError($errRecord)
}

function Get-BuildScriptTasks
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $false)]
        [string]$BuildFile
    )

    if (-not $BuildFile) 
    {
        $BuildFile = $BuildEnv.DefaultSetting.BuildFileName
    }

    try
    {
        ExecuteInBuildFileScope {
            Param($CurrentContext, $Module)

            return GetTasksFromContext $CurrentContext
        } -BuildFile $BuildFile -Module ($MyInvocation.MyCommand.Module) 
    } 
    finally 
    {
        CleanupEnvironment
    }
}

function Invoke-Builder 
{
    # .EXTERNALHELP Builder-Help.xml

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $false)]
        [string]$BuildFile,

        [Parameter(Position = 2, Mandatory = $false)]
        [string[]]$TaskList = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Docs,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},

        [Parameter(Mandatory = $false)]
        $Properties = @{},
        
        [Parameter(Mandatory = $false)]
        [Alias('Init')]
        [scriptblock]$Initialization = {},

        [Parameter(Mandatory = $false)]
        [switch]$NoLogo,

        [Parameter(Mandatory = $false)]
        [switch]$DetailDocs,

        [Parameter(Mandatory = $false)]
        [switch]$TimeReport
    )

    try 
    {
        if (-not $NoLogo) 
        {
            $logoText = @(
                ('Builder {0}' -f $BuildEnv.Version)
                'Copyright (c) 2018 Lizoc Inc. All rights reserved.'
                ''
            ) -join [Environment]::NewLine
            Write-Output $logoText
        }

        if (-not $BuildFile) 
        {
          $BuildFile = $BuildEnv.DefaultSetting.BuildFileName
        }
        elseif (-not (Test-Path $BuildFile -PathType Leaf) -and 
            (Test-Path $BuildEnv.DefaultSetting.BuildFileName -PathType Leaf)) 
        {
            # if the $config.buildFileName file exists and the given "buildfile" isn 't found assume that the given
            # $buildFile is actually the target Tasks to execute in the $config.buildFileName script.
            $taskList = $BuildFile.Split(', ')
            $BuildFile = $BuildEnv.DefaultSetting.BuildFileName
        }

        ExecuteInBuildFileScope -BuildFile $BuildFile -Module ($MyInvocation.MyCommand.Module) -ScriptBlock {
            Param($CurrentContext, $Module)            

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            if ($Docs -or $DetailDocs) 
            {
                WriteDocumentation -Detail:$DetailDocs
                return
            }
            
            foreach ($key in $Parameters.Keys) 
            {
                if (Test-Path "Variable:\$key") 
                {
                    Set-Item -Path "Variable:\$key" -Value $Parameters.$key -WhatIf:$false -Confirm:$false | Out-Null
                } 
                else 
                {
                    New-Item -Path "Variable:\$key" -Value $Parameters.$key -WhatIf:$false -Confirm:$false | Out-Null
                }
            }
            
            # The initial dot (.) indicates that variables initialized/modified in the propertyBlock are available in the parent scope.
            foreach ($propertyBlock in $CurrentContext.Properties) 
            {
                . $propertyBlock
            }
            
            foreach ($key in $Properties.Keys) 
            {
                if (Test-Path "Variable:\$key") 
                {
                    Set-Item -Path "Variable:\$key" -Value $Properties.$key -WhatIf:$false -Confirm:$false | Out-Null
                }
            }
            
            # Simple dot sourcing will not work. We have to force the script block into our
            # module's scope in order to initialize variables properly.
            . $Module $Initialization
            
            # Execute the list of tasks or the default task
            if ($taskList) 
            {
                foreach ($task in $taskList) 
                {
                    Invoke-Task $task
                }
            } 
            elseif ($CurrentContext.Tasks.Default) 
            {
                Invoke-Task default
            } 
            else 
            {
                Die $PBLocalizedData.Err_NoDefaultTask 'NoDefaultTask'
            }
            
            $outputMessage = @(
                ''
                $PBLocalizedData.BuildSuccess
                ''
            ) -join [Environment]::NewLine

            WriteColoredOutput $outputMessage -ForegroundColor Green
            
            $stopwatch.Stop()
            if ($TimeReport) 
            {
                WriteTaskTimeSummary $stopwatch.Elapsed
            }
        }

        $BuildEnv.BuildSuccess = $true
    } 
    catch 
    {
        $currentConfig = GetCurrentConfigurationOrDefault
        if ($currentConfig.VerboseError) 
        {
            $errMessage = @(
                ('[{0}] {1}' -f (Get-Date).ToString('hhmm:ss'), $PBLocalizedData.ErrorHeaderText)
                ''
                ('{0}: {1}' -f $PBLocalizedData.ErrorLabel, (ResolveError $_ -Short))
                $PBLocalizedData.Divider
                (ResolveError $_)  # this will have enough blank lines appended
                $PBLocalizedData.Divider
                $PBLocalizedData.VariableLabel
                $PBLocalizedData.Divider
                (Get-Variable -Scope Script | Format-Table | Out-String)
            ) -join [Environment]::NewLine
        } 
        else 
        {
            # ($_ | Out-String) gets error messages with source information included.
            $errMessage = '[{0}] {1}: {2}' -f (Get-Date).ToString('hhmm:ss'), $PBLocalizedData.ErrorLabel, (ResolveError $_ -Short)
        }

        $BuildEnv.BuildSuccess = $false

        # if we are running in a nested scope (i.e. running a build script from within another build script) then we need to re-throw the exception
        # so that the parent script will fail otherwise the parent script will report a successful build
        $inNestedScope = ($BuildEnv.Context.Count -gt 1)
        if ($inNestedScope) 
        {
            Die $_
        } 
        else 
        {
            if (-not $BuildEnv.RunByUnitTest) 
            {
                WriteColoredOutput $errMessage -ForegroundColor Red
            }
        }
    } 
    finally 
    {
        CleanupEnvironment
    }
}


#######################################################################
#  Private module functions
#######################################################################

function WriteColoredOutput 
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Message,

        [Parameter(Mandatory = $true, Position = 2)]
        [System.ConsoleColor]$ForegroundColor
    )

    $currentConfig = GetCurrentConfigurationOrDefault
    if ($currentConfig.ColoredOutput -eq $true) 
    {
        if (($Host.UI -ne $null) -and 
            ($Host.UI.RawUI -ne $null) -and 
            ($Host.UI.RawUI.ForegroundColor -ne $null)) 
        {
            $previousColor = $Host.UI.RawUI.ForegroundColor
            $Host.UI.RawUI.ForegroundColor = $ForegroundColor
        }
    }

    Write-Output $message

    if ($previousColor -ne $null) 
    {
        $Host.UI.RawUI.ForegroundColor = $previousColor
    }
}

function ExecuteInBuildFileScope 
{
    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true)]
        [string]$BuildFile, 

        [Parameter(Mandatory = $true)]
        $Module
    )
    
    # Execute the build file to set up the tasks and defaults
    Assert (Test-Path $BuildFile -PathType Leaf) -ErrorMessage ($PBLocalizedData.Err_BuildFileNotFound -f $BuildFile)

    $BuildEnv.BuildScriptFile = Get-Item $BuildFile
    $BuildEnv.BuildScriptDir = $BuildEnv.BuildScriptFile.DirectoryName
    $BuildEnv.BuildSuccess = $false

    $BuildEnv.Context.Push(@{
        'TaskSetupScriptBlock' = {}
        'TaskTearDownScriptBlock' = {}
        'ExecutedTasks' = New-Object System.Collections.Stack
        'CallStack' = New-Object System.Collections.Stack
        'OriginalEnvPath' = $env:Path
        'OriginalDirectory' = Get-Location
        'OriginalErrorActionPreference' = $global:ErrorActionPreference
        'Tasks' = @{}
        'Aliases' = @{}
        'Properties' = @()
        'Will' = @()
        'Includes' = New-Object System.Collections.Queue
        'Setting' = CreateConfigurationForNewContext -BuildFile $BuildFile
    })

    LoadConfiguration $BuildEnv.BuildScriptDir

    Set-Location $BuildEnv.BuildScriptDir

    LoadModules

    . $BuildEnv.BuildScriptFile.FullName

    $CurrentContext = $BuildEnv.Context.Peek()

    ConfigureBuildEnvironment

    while ($CurrentContext.Includes.Count -gt 0) 
    {
        $includeFilename = $CurrentContext.Includes.Dequeue()
        . $includeFilename
    }

    & $ScriptBlock $CurrentContext $Module
}

function WriteDocumentation
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [switch]$Detail
    )

    $currentContext = $BuildEnv.Context.Peek()

    if ($currentContext.Tasks.Default) 
    {
        $defaultTaskDependencies = $currentContext.Tasks.Default.DependsOn
    } 
    else
    {
        $defaultTaskDependencies = @()
    }
    
    $docs = GetTasksFromContext $currentContext | where {
        $_.Name -ne 'default'
    } | ForEach-Object {
        $isDefault = $null
        if ($defaultTaskDependencies -contains $_.Name) 
        { 
            $isDefault = $true 
        }
        
        Add-Member -InputObject $_ 'Default' $isDefault -Passthru
    }

    if ($Detail) 
    {
        $docs | sort 'Name' | Format-List -Property Name, Alias, Description, @{
            Label = 'Depends On'
            Expression = { $_.DependsOn -join ', '}
        }, Default
    } 
    else 
    {
        $docs | sort 'Name' | Format-Table -AutoSize -Wrap -Property Name, Alias, @{
            Label = 'Depends On'
            Expression = { $_.DependsOn -join ', ' }
        }, Default, Description
    }
}

function ResolveError
{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $ErrorRecord = $Error[0],

        [Parameter(Mandatory = $false)]
        [switch]$Short
    )

    Process 
    {
        if ($_ -eq $null) 
        { 
            $_ = $ErrorRecord 
        }
        $ex = $_.Exception

        if (-not $Short) 
        {
            $errMessage = @(
                ''
                'ErrorRecord:{0}ErrorRecord.InvocationInfo:{1}Exception:'
                '{2}'
                ''
            ) -join [Environment]::NewLine

            $formattedErrRecord = $_ | Format-List * -Force | Out-String
            $formattedInvocationInfo = $_.InvocationInfo | Format-List * -Force | Out-String
            $formattedException = ''

            $i = 0
            while ($ex -ne $null) 
            {
                $i++
                $formattedException += @(
                    ("$i" * 70)
                    ($ex | Format-List * -Force | Out-String)
                    '' 
                ) -join [Environment]::NewLine

                $ex = $ex | SelectObjectWithDefault -Name 'InnerException' -Value $null
            }

            return $errMessage -f $formattedErrRecord, $formattedInvocationInfo, $formattedException
        }

        $lastException = @()
        while ($ex -ne $null) 
        {
            $lastMessage = $ex | SelectObjectWithDefault -Name 'Message' -Value ''
            $lastException += ($lastMessage -replace [Environment]::NewLine, '')

            if ($ex -is [Data.SqlClient.SqlException]) 
            {
                $lastException = '(Line [{0}] Procedure [{1}] Class [{2}] Number [{3}] State [{4}])' -f $ex.LineNumber, $ex.Procedure, $ex.Class, $ex.Number, $ex.State
            }
            $ex = $ex | SelectObjectWithDefault -Name 'InnerException' -Value $null
        }
        $shortException = $lastException -join ' --> '

        $header = $null
        $current = $_
        $header = (($_.InvocationInfo | SelectObjectWithDefault -Name 'PositionMessage' -Value '') -replace [Environment]::NewLine, ' '),
            ($_ | SelectObjectWithDefault -Name 'Message' -Value ''),
            ($_ | SelectObjectWithDefault -Name 'Exception' -Value '') | where { -not [String]::IsNullOrEmpty($_) } | select -First 1

        $delimiter = ''
        if ((-not [String]::IsNullOrEmpty($header)) -and
            (-not [String]::IsNullOrEmpty($shortException)))
        { 
            $delimiter = ' [<<==>>] ' 
        }

        return '{0}{1}Exception: {2}' -f $header, $delimiter, $shortException
    }
}

function LoadModules 
{
    $currentConfig = $BuildEnv.Context.Peek().Setting
    if ($currentConfig.Modules) 
    {
        $scope = $currentConfig.ModuleScope
        $global = [string]::Equals($scope, 'global', [StringComparison]::CurrentCultureIgnoreCase)

        $currentConfig.Modules | ForEach-Object {
            Resolve-Path $_ | ForEach-Object {
                # "Loading module: $_"
                $module = Import-Module $_ -PassThru -DisableNameChecking -Global:$global -Force

                if (-not $module) 
                {
                    Die ($PBLocalizedData.Err_LoadingModule -f $_.Name) 'LoadModuleError'
                }
            }
        }

        Write-Output ''
    }
}

function LoadConfiguration 
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $PSScriptRoot
    )

    $pbConfigFilePath = Join-Path $ConfigPath -ChildPath "Builder-Config.ps1"

    if (Test-Path $pbConfigFilePath -PathType Leaf) 
    {
        try 
        {
            $config = GetCurrentConfigurationOrDefault
            . $pbConfigFilePath
        } 
        catch 
        {
            Die ($PBLocalizedData.Err_LoadConfig + ': ' + $_) 'LoadConfigError'
        }
    }
}

function GetCurrentConfigurationOrDefault() 
{
    if ($BuildEnv.Context.Count -gt 0) 
    {
        $BuildEnv.Context.Peek().Setting
    } 
    else 
    {
        $BuildEnv.DefaultSetting
    }
}

function CreateConfigurationForNewContext 
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$BuildFile
    )

    $previousConfig = GetCurrentConfigurationOrDefault

    $config = New-Object PSObject -Property @{
        BuildFileName = $previousConfig.BuildFileName
        EnvPath = $previousConfig.EnvPath
        TaskNameFormat = $previousConfig.TaskNameFormat
        VerboseError = $previousConfig.VerboseError
        ColoredOutput = $previousConfig.ColoredOutput
        Modules = $previousConfig.Modules
        ModuleScope = $previousConfig.ModuleScope
        VerboseLevel = $previousConfig.VerboseLevel
    }

    if ($BuildFile) 
    {
        $config.BuildFileName = $BuildFile
    }

    $config
}

function ConfigureBuildEnvironment 
{
    $envPathDirs = @($BuildEnv.Context.Peek().Setting.EnvPath) | where { ($_ -ne $null) -and ($_ -ne '') }

    if ($envPathDirs)
    {
        $envPathDirs | ForEach-Object { 
            Assert (Test-Path $_ -PathType Container) -ErrorMessage ($PBLocalizedData.Err_EnvPathDirNotFound -f $_)
        }
        
        $newEnvPath = @($env:Path.Split([System.IO.Path]::PathSeparator), $envPathDirs) | select -Unique

        $env:Path = $newEnvPath -join [System.IO.Path]::PathSeparator
    }

    # if any error occurs in a PS function then "stop" processing immediately
    # this does not effect any external programs that return a non-zero exit code
    $global:ErrorActionPreference = 'Stop'
}

function CleanupEnvironment 
{
    if ($BuildEnv.Context.Count -gt 0) 
    {
        $currentContext = $BuildEnv.Context.Peek()
        $env:Path = $currentContext.OriginalEnvPath
        Set-Location $currentContext.OriginalDirectory
        $global:ErrorActionPreference = $currentContext.OriginalErrorActionPreference
        [void]$BuildEnv.Context.Pop()
    }
}

function SelectObjectWithDefault
{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [psobject]$InputObject,

        [Parameter(ValueFromPipeline = $false)]
        [string]$Name,

        [Parameter(ValueFromPipeline = $false)]
        $Value
    )

    Process 
    {
        if ($_ -eq $null) 
        { 
            $Value 
        }
        elseif ($_ | Get-Member -Name $Name) 
        {
            $_."$Name"
        }
        elseif (($_ -is [Hashtable]) -and ($_.Keys -contains $Name)) 
        {
            $_."$Name"
        }
        else 
        { 
            $Value 
        }
    }
}

function GetTasksFromContext 
{
    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        $CurrentContext
    )

    $CurrentContext.Tasks.Keys | ForEach-Object {
        $task = $CurrentContext.Tasks."$_"

        New-Object PSObject -Property @{
            Name = $task.Name
            Alias = $task.Alias
            Description = $task.Description
            DependsOn = $task.DependsOn
        }
    }
}

function WriteTaskTimeSummary 
{
    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        $Duration
    )

    if ($BuildEnv.Context.Count -gt 0) 
    {
        Write-Output $PBLocalizedData.Divider
        Write-Output $PBLocalizedData.BuildTimeReportTitle
        Write-Output $PBLocalizedData.Divider

        $list = @()
        $currentContext = $BuildEnv.Context.Peek()
        while ($currentContext.ExecutedTasks.Count -gt 0) 
        {
            $taskKey = $currentContext.ExecutedTasks.Pop()
            $task = $currentContext.Tasks.$taskKey
            if ($taskKey -eq 'default') 
            {
                continue
            }
            $list += New-Object PSObject -Property @{
                Name = $task.Name
                Duration = $task.Duration
            }
        }
        [Array]::Reverse($list)
        $list += New-Object PSObject -Property @{
            Name = 'Total'
            Duration = $Duration
        }

        # using "out-string | where-object" to filter out the blank line that format-table prepends
        $list | Format-Table -AutoSize -Property Name, Duration | Out-String -Stream | where { $_ }
    }
}


#######################################################################
#  Main
#######################################################################

$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $scriptDir -ChildPath 'Builder.psd1'
$manifest = Test-ModuleManifest -Path $manifestPath -WarningAction $(
    if ($PSVersionTable.PSVersion.Major -ge 3) { 'Ignore' } 
    else { 'SilentlyContinue' }
)

$script:BuildEnv = @{}

$BuildEnv.Version = $manifest.Version.ToString()
$BuildEnv.Context = New-Object System.Collections.Stack   # holds onto the current state of all variables
$BuildEnv.RunByUnitTest = $false                          # indicates that build is being run by internal unit tester

# contains default configuration, can be overriden in Builder-Config.ps1 in directory with Builder.psm1 or in directory with current build script
$BuildEnv.DefaultSetting = New-Object PSObject -Property @{
    BuildFileName = 'default.ps1'
    EnvPath = $null
    TaskNameFormat = $PBLocalizedData.DefaultTaskNameFormat
    VerboseError = $false
    ColoredOutput = $true
    Modules = $null
    ModuleScope = ''
    VerboseLevel = 2
} 

$BuildEnv.BuildSuccess = $false     # indicates that the current build was successful
$BuildEnv.BuildScriptFile = $null   # contains a System.IO.FileInfo for the current build script
$BuildEnv.BuildScriptDir = ''       # contains a string with fully-qualified path to current build script
$BuildEnv.ModulePath = $PSScriptRoot

LoadConfiguration

Export-ModuleMember -Function @(
    'Invoke-Builder', 'Invoke-Task', 'Get-BuildScriptTasks',
    'Task', 'PrintTask', 'TaskSetup', 'TaskTearDown', 
    'Properties', 'Include', 'Will', 'EnvPath', 'Assert', 'Exec', 'Say', 'Die'
) -Variable @(
    'BuildEnv'
)

