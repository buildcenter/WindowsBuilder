properties {
    [string]$Subcommand = 'Build'

    # where Subcommand = 'Build'
    [string]$Configuration = 'global'

    # where Subcommand = 'Help'
    [string]$HelpTopic = ''

    # where Subcommand = 'Dismount'
    [bool]$Undo = $false

    # where Subcommand = 'Mount'
    [bool]$ListAvailable = $false
    [int]$ImageIndex = -1
    [string]$ReferenceImagePath = $null

    # where Subcommand = 'Driver'
    [bool]$DumpDriver = $false
}

printTask {
    param($taskName)

    if ($taskName -notin @('Help', 'Localize'))
    {
        say -NewLine -LineCount 3
        say ('+-' + ('-' * $taskName.Length) + '-+') -fg Blue
        say ('| {0} |' -f $taskName) -fg Blue
        say ('+-' + ('-' * $taskName.Length) + '-+') -fg Blue
    }
}

task default -depends Finish

task Localize {
    $psIgnoreAction = $(
        if ($PSVersionTable.PSVersion.Major -ge 3) { 'Ignore' } 
        else { 'SilentlyContinue' }
    )

    $noImportLocalizedDataCmdletErr = $null
    Get-Command Import-LocalizedData -ErrorVariable noImportLocalizedDataCmdletErr -ErrorAction $psIgnoreAction | Out-Null

    if ($noImportLocalizedDataCmdletErr[0] -eq $null)
    {
        Import-LocalizedData -BindingVariable BMLocalizedData -BaseDirectory $BuildEnv.BuildScriptDir -FileName 'Message.psd1'
    }
    else
    {
        die "Unable to find command 'Import-LocalizedData'. The Powershell application available may be incompatible."
    }

    $BuildEnv.BMLocalizedData = $BMLocalizedData
}

task Help -depends Localize -precondition { $Subcommand -eq 'Help' } {
    $sr = $BuildEnv.BMLocalizedData

    $availHelpTopics = dir (Join-Path $BuildEnv.BuildScriptDir -ChildPath "$($sr.LocaleName)/about_*.txt") -File | select -expand BaseName

    if ($HelpTopic)
    {
        
        $helpTopicFile = Join-Path $BuildEnv.BuildScriptDir -ChildPath "$($sr.LocaleName)/about_$HelpTopic.txt"
        if (-not (Test-Path $helpTopicFile -PathType Leaf))
        {
            say ($sr.HelpTopicNotFound -f $HelpTopic) -v 0
            $availHelpTopics | ForEach-Object {
                say ('- {0}' -f $_.Substring('about_'.Length))
            }
        }
        else
        {
            say ('{0}' -f $HelpTopic) -fg Magenta
            say ('{0}' -f ('=' * $HelpTopic.Length)) -fg Magenta
            $helpTopicContent = Get-Content -Path $helpTopicFile -Encoding UTF8
            say ($helpTopicContent -join [Environment]::NewLine)
        }

        exit 0
    }

    $syntax = @(
        'build /?|/help|-h|--help [help_topic]'
        'build configure'
        'build mount'
        'build mount <path\to\install.wim> [?|<index>]'
        'build dismount [undo]'
        'build [configuration]'
        'build driver dump'
    )

    $examples = @{}
    $exampleCounter = 1
    @(
    	'build'
    	'build win10'
    	'build mount'
    ) | ForEach-Object {
        $examples."$_" = @()
        for ($i = 1; $i -lt 100; $i++)
        {
            $exampleLineName = 'Example{0}_{1}' -f $exampleCounter, $i
            if (-not $sr."$exampleLineName")
            {
                break
            }
            else
            {
                $examples."$_" += $sr."$exampleLineName"
            }
        }
        $exampleCounter += 1
    }

    $author = $sr.Author
    $version = $sr.Version

    # -------------------------------------

    say $sr.Syntax -fg Magenta
    $syntax | ForEach-Object {
        say "    $_" -fg Green
    }

    say -NewLine -LineCount 2

    $exampleCounter = 1
    $examples.Keys | ForEach-Object {
        say ('{0} #{1}' -f $sr.Example, $exampleCounter) -fg Magenta
        say ('    ' + $_) -fg Green
        say -NewLine
        say ('    {0}' -f $sr.Description) -fg Cyan
        say ('    {0}' -f ('-' * $sr.Description.Length)) -fg Cyan
        $examples."$_" | ForEach-Object {
            if ($_) { say ('    ' + $_) }
            else { say -NewLine }
        }
        say -NewLine

        $exampleCounter += 1
    }

    say $sr.Remarks -fg Magenta
    say ('    {0} {1}' -f $sr.VersionLabel, $version)
    say ('    {0} {1}' -f $sr.AuthorLabel, $author)

    if ($availHelpTopics)
    {
        say -NewLine
        say $sr.HelpTopics -fg Magenta
        say '    build /? [help_topic]' -fg Green
        say -NewLine
        $availHelpTopics | ForEach-Object {
            say ('    - {0}' -f $_.Substring('about_'.Length))
        }
    }

    exit 0
}

task Precheck -depends Localize {
    $sr = $BuildEnv.BMLocalizedData

    $supportedSubcommands = @('Build', 'Mount', 'Dismount', 'Help', 'Configure', 'Driver')
    assert ($Subcommand -in $supportedSubcommands) ($sr.UnsupportedSubcommand -f $Subcommand, ($supportedSubcommands -join ', '))

    # Configuration check. We still need to check further in setup
    if ($Subcommand -in @('Build', 'Mount'))
    {
        assert ($Configuration -ne '') ($sr.ConfigurationNullOrEmpty)
    }

    # must runas admin
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    assert $isAdmin $sr.RequireRunAsAdmin
}

task Setup -depends Precheck {
    $sr = $BuildEnv.BMLocalizedData

    # basic assumption -- tools folder is 1 level above this script
    $BuildEnv.windowsBuilderDir = $BuildEnv.BuildScriptDir
    $BuildEnv.toolsDir = (Get-Item $BuildEnv.BuildScriptDir).Parent.FullName
    $BuildEnv.rootDir = Get-Item $BuildEnv.BuildScriptDir | select -expand Root | select -expand FullName
    $BuildEnv.repoDir = (Get-Item $BuildEnv.toolsDir).Parent.FullName
    $BuildEnv.sourceDir = Join-Path $BuildEnv.repoDir -ChildPath 'src'

    # ~~~~~~~~~~~~~~~~~
    # import modules
    # ~~~~~~~~~~~~~~~~~
    say ($sr.ImportingModules)
    @(
        'PSJapson/Lizoc.PowerShell.Japson.dll'
        'PSTemplate.psm1'
        'WindowsBuilder/WindowsBuildHelper.psm1'
    ) | ForEach-Object {
        say ('* {0}' -f $_) -v 2
        ipmo (Join-Path $BuildEnv.toolsDir -ChildPath $_) -Force
    }


    # ~~~~~~~~~~~~~~~~~
    # global config
    # ~~~~~~~~~~~~~~~~~

    # The default bsd content that real bsd files will override
    $defaultBsd = @(
        "build-configuration = '{0}'" -f $Configuration
        ''
        '# --- env ---'
        "hostOS = '{0}'" -f $env:OS
        "dirSeparator = '{0}'" -f [System.IO.Path]::DirectorySeparatorChar.ToString().Replace('\', '\\')
        ''
        '# --- paths ---'
        "windowsBuilderDir = '{0}'" -f $BuildEnv.windowsBuilderDir.Replace('\', '\\')
        "toolsDir = '{0}'" -f $BuildEnv.toolsDir.Replace('\', '\\')
        "rootDir = '{0}'" -f $BuildEnv.rootDir.Replace('\', '\\')
        "repoDir = '{0}'" -f $BuildEnv.repoDir.Replace('\', '\\')
        "sourceDir = '{0}'" -f $BuildEnv.sourceDir.Replace('\', '\\')
        # overridable
        'tempDir = ${repoDir}' + "'\\temp'"
        'workingDir = ${repoDir}' + "'\\working'"
        'mountDir = ${workingDir}' + "'\\mount'"
        'resDir = ${repoDir}' + "'\\resource'"
        'outputDir = ${workingDir}' + "'\\output'"
        # hardcode
        'templateHelperScriptFile = ${toolsDir}' + "'\\template_helpers.ps1'"
        ''
        '# --- registry ---'
        'registryMountPoint {'
	    "    'Windows/System32/config/COMPONENTS' = 'HKLM:\\svc_components'"
	    "    'Windows/System32/config/DEFAULT' = 'HKLM:\\svc_default'"
	    "    'Windows/System32/config/DRIVERS' = 'HKLM:\\svc_drivers'"
	    "    'Windows/System32/config/SAM' = 'HKLM:\\svc_sam'"
	    "    'Windows/System32/config/SECURITY' = 'HKLM:\\svc_security'"
	    "    'Windows/System32/config/SOFTWARE' = 'HKLM:\\svc_software'"
	    "    'Windows/System32/config/SYSTEM' = 'HKLM:\\svc_system'"
        "    'Users/Default/NTUSER.DAT' = 'HKLM:\\svc_user'"
        '}'
    )

    # parse!
    $defaultConfig = ConvertFrom-Japson ($defaultBsd -join [Environment]::NewLine)
    $defaultConfigReservedKeys = $defaultConfig | Get-Member -MemberType NoteProperty | select -expand Name

    # override with src/global.bsd
    $defaultConfigPath = Join-Path $BuildEnv.repoDir -ChildPath 'src\global.bsd'
    assert (Test-Path $defaultConfigPath -PathType Leaf) ($sr.DefaultConfigFileNotFound -f $defaultConfigPath)
    say $sr.ImportingDefaultConfig
    $defaultBsd += Get-Content $defaultConfigPath -Encoding UTF8

    if ($Configuration -and ($Configuration -ne 'global'))
    {
        $customConfigPath = Join-Path $BuildEnv.repoDir -ChildPath "src\$Configuration.bsd"
        assert (Test-Path $customConfigPath -PathType Leaf) ($sr.CustomConfigFileNotFound -f $customConfigPath)
        $defaultBsd += Get-Content $customConfigPath -Encoding UTF8
    }
    else
    {
        say ($sr.UsingDefaultConfig)
    }

    # parse!
    $globalConfig = ConvertFrom-Japson ($defaultBsd -join [Environment]::NewLine)

    # make sure bsd doesn't contain reserved property names
    $allGlobalConfigKeys = $globalConfig | Get-Member -MemberType NoteProperty | select -expand Name
    $ignoreConfigKeys = @('toolsDir', 'rootDir', 'repoDir', 'sourceDir', 'windowsBuilderDir')
    $allGlobalConfigKeys | where { $_ -notin $ignoreConfigKeys } | ForEach-Object {
        assert ($_ -ne 'Keys') ($sr.ConfigPropertyNameReserved -f 'Keys')
        assert ($_ -ne 'Reserved') ($sr.ConfigPropertyNameReserved -f 'Reserved')
        assert ($_ -notin $BuildEnv.Keys) ($sr.ConfigPropertyNameReserved -f $_)
    }

    # keep a record of reserved keys
    $reservedKeys = $BuildEnv.Keys | where { $_ -notin $ignoreConfigKeys }
    $reservedKeys += 'Reserved'
    $reservedKeys += 'globalConfigText'
    $reservedKeys += $defaultConfigReservedKeys

    # now they are all safe
    # note that some special properties are not overridable by custom config: ignoreConfigKeys
    $allGlobalConfigKeys | where { $_ -notin $ignoreConfigKeys } | ForEach-Object {
        $BuildEnv."$_" = $globalConfig."$_"
    }

    $BuildEnv.globalConfigText = $globalBsd

    $BuildEnv.Reserved = $reservedKeys

    # ~~~~~~~~~~~~~~~~~
    # check prerequisite files and folders
    # ~~~~~~~~~~~~~~~~~
    if ($Subcommand -eq 'Configure')
    {
        # template helper
	    if (-not $BuildEnv.templateHelperScriptFile)
	    {
	        $BuildEnv.templateHelperScriptFile = Join-Path $BuildEnv.toolsDir -ChildPath 'template_helpers.ps1'
	    }
	    assert (Test-Path $BuildEnv.templateHelperScriptFile -PathType Leaf) ($sr.RequiredFileNotFound -f $BuildEnv.templateHelperScriptFile)

        # source dir
	    assert (Test-Path $BuildEnv.sourceDir -PathType Container) ($sr.RequiredFolderNotFound -f $BuildEnv.sourceDir)
	}

    # ~~~~~~~~~~~~~~~~~
    # set up folders
    # ~~~~~~~~~~~~~~~~~
    if ($Subcommand -eq 'Configure')
    {
        @('workingDir', 'mountDir', 'outputDir', 'tempDir', 'resDir') | ForEach-Object {
	        if (-not (Test-Path $BuildEnv."$_" -PathType Container))
	        {
	            if (Test-Path $BuildEnv."$_" -PathType Leaf) 
	            {
	                say ($sr.RemovingUnexpectedFile -f $BuildEnv."$_") -v 0
	                del $BuildEnv."$_"
	            }

	            say ($sr.CreatingFolder -f $BuildEnv."$_")
	            md $BuildEnv."$_" -Force | Out-Null
	        }
        }
	}
    else
    {
        @('workingDir', 'mountDir', 'outputDir', 'tempDir', 'resDir') | ForEach-Object {
            assert (Test-Path $BuildEnv."$_" -PathType Container) ($sr.RequiredFolderNotFound -f $BuildEnv."$_")
        }
    }

    if ($Subcommand -eq 'Build')
    {
        @(
            'Windows/System32/config/COMPONENTS'
	        'Windows/System32/config/DEFAULT'
	        'Windows/System32/config/DRIVERS'
	        'Windows/System32/config/SAM'
	        'Windows/System32/config/SECURITY'
	        'Windows/System32/config/SOFTWARE'
	        'Windows/System32/config/SYSTEM'
            'Users/Default/NTUSER.DAT'
        ) | ForEach-Object {
            assert ($BuildEnv.registryMountPoint."$_" -like 'HKLM:\*') ($sr.RegistryMountPointNotSpecifiedOrInvalid -f $_, $BuildEnv.registryMountPoint."$_")
            assert (-not (Test-Path $BuildEnv.registryMountPoint."$_")) ($sr.RegistryMountPointExists -f $BuildEnv.registryMountPoint."$_")
        }
    }
}

task Discover -depends Setup {
    $sr = $BuildEnv.BMLocalizedData

    # all folders in /src are modules
    say ($sr.DiscoveringAvailableModules)
    $availModules = dir $BuildEnv.sourceDir -Directory | select -expand Name

    $validModules = @()
    $availModules | where { $_ -ne $null } | ForEach-Object {
        $isModule = Test-Path (Join-Path $BuildEnv.sourceDir -ChildPath "$_/Install.ps1") -PathType Leaf
        if (-not $isModule)
        {
            say ($sr.NotModule -f $_) -v 0
        }
        else
        {
            if ($_ -in $BuildEnv.Reserved)
            {
                say ($sr.ModuleCannotUseReservedName -f $_) -v 0
            }
            else
            {
                say ("- {0}" -f $_)
                $validModules += $_
            }
        }
    }

    $BuildEnv.AvailableModule = $validModules
}

task Configure -depends Discover -precondition { $Subcommand -eq 'Configure' } {
    $sr = $BuildEnv.BMLocalizedData

    if ($BuildEnv.AvailableModule.Count -eq 0)
    {
        say $sr.NoModuleAvailable -v 0
        return
    }
}

task Mount -depends Setup -precondition { $Subcommand -eq 'Mount' } {
    $sr = $BuildEnv.BMLocalizedData

    if ((-not $ReferenceImagePath) -or ($ReferenceImagePath -eq ''))
    {
        # interactive
        say ($sr.PromptWimFilePath)
        $refWimPath = Read-Host -Prompt '>'
    }
    else
    {
        $refWimPath = $ReferenceImagePath
    }

    if (-not [system.io.path]::IsPathRooted($refWimPath))
    {
        $refWimPath = Join-Path $BuildEnv.repoDir -ChildPath $refWimPath
    }
    $refWimPath = Resolve-Path $refWimPath | select -expand Path

    assert (Test-Path $refWimPath -PathType Leaf) ($sr.ReferenceImageFileNotFound -f $refWimPath)

    if (($ListAvailable -eq $true) -or ($ImageIndex -lt 1))
    {
        say ($sr.ReadingWimEntries)
        Get-WindowsImage -ImagePath $refWimPath
    }

    if ($ListAvailable -ne $true)
    {
        if ($ImageIndex -lt 1)
        {
            say ($sr.PromptWimImageIndex)
            $refWimIndex = Read-Host -Prompt '>'
        }
        else
        {
            $refWimIndex = $ImageIndex
        }

        say ($sr.MountingImage -f $refWimPath, $refWimIndex, $BuildEnv.mountDir)
        Mount-WindowsImage -Path $BuildEnv.mountDir -ImagePath $refWimPath -Index $refWimIndex
    }
}

task Dismount -depends Setup -precondition { $Subcommand -eq 'Dismount' } {
    $sr = $BuildEnv.BMLocalizedData

    if ($Undo -eq $true)
    {
        say $sr.DismountDiscardChange
        Dismount-WindowsImage -Path $BuildEnv.mountDir -Discard
    }
    else
    {
        say $sr.DismountSaveChange
        Dismount-WindowsImage -Path $BuildEnv.mountDir -Save
    }
}

task Driver -depends Setup -precondition { $Subcommand -eq 'Driver' } {
    $sr = $BuildEnv.BMLocalizedData

    if ($DumpDriver -eq $true)
    {
        $driverOutputPath = Join-Path $BuildEnv.resDir -ChildPath 'Drivers'
        if (Test-Path $driverOutputPath)
        {
            say ($sr.RemovingExistingDriverDump -f $driverOutputPath)
            rd $driverOutputPath -Recurse -Force
        }
        md $driverOutputPath | Out-Null

        say ($sr.DumpingDrivers -f $driverOutputPath)
        Export-WindowsDriver -Online -Destination $driverOutputPath
    }
    else
    {
        say ($sr.DriverCommandNothingToDo)
    }
}

task Build -depends Discover -precondition { $Subcommand -eq 'Build' } {
    $sr = $BuildEnv.BMLocalizedData

    $targetModules = @()

    if ($BuildEnv.AvailableModule.Count -eq 0)
    {
        say $sr.NoModuleAvailable -v 0
        return
    }
    else
    {
        $BuildEnv.AvailableModule | ForEach-Object {
            if ($_ -in $BuildEnv.Keys)
            {
                $targetModules += $_
            }
        }
    }
    say ($targetModules -join ', ')

    if ($targetModules.Count -eq 0)
    {
        say $sr.NoTargetModule -v 0
        return
    }

    for ($i = 0; $i -lt $targetModules.Count; $i++)
    {
        $moduleName = $targetModules[$i]

        if ($i -ne 0) { say -Divider }
        say ($sr.StartBuildModule -f $moduleName)
        if ($i -eq 0) { say -Divider }

        $moduleScriptPath = Join-Path $BuildEnv.sourceDir -ChildPath "$moduleName\Install.ps1"
        Invoke-Builder $moduleScriptPath -NoLogo
        
        continue
    }
}

task Finish -depends Help, Configure, Build, Mount, Dismount, Driver {
    $sr = $BuildEnv.BMLocalizedData

    say $sr.Goodbye
    say -NewLine -LineCount 5
}