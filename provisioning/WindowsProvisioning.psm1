function Install-WindowsImage
{
    <#
        .NOTES
            Copyright (c) 2018 Lizoc Corporation. All rights reserved.

            Use of this sample source code is subject to the terms of the Lizoc
            license agreement under which you licensed this sample source code. If
            you did not accept the terms of the license agreement, you are not
            authorized to use this sample source code. For the terms of the license,
            please see the license agreement between you and Lizoc or, if applicable,
            see the LICENSE.txt file on your install media or the root of your tools 
            installation.

            THE SAMPLE SOURCE CODE IS PROVIDED "AS IS", WITH NO WARRANTIES.

        .SYNOPSIS
            Installs the Windows operating system onto a physical disk or VHD.

        .DESCRIPTION
            This command is used to provision a Windows image in the WIM format to a 
            VHD or physical disk. The target disk will be formatted.

            You can run this command in Windows with or without Hyper-V feature installed, 
            including Windows PE.

            Kernel debugging support can be configured using the "EnableDebugger" parameter.

        .OUTPUTS
            System.IO.FileInfo
            Microsoft.Management.Infrastructure.CimInstance#ROOT/Microsoft/Windows/Storage/MSFT_Disk

        .PARAMETER ImagePath
            The complete path to the WIM file that will be applied to a disk.

            You can also specify a SWM file, which is WIM in a splitted format. See the examples below and 
            the command "Split-WindowsImage" for details.

        .PARAMETER VHDPath
            The path to an existing Virtual Hard Disk file.

            This command will provision the specified Windows image onto the designated VHD.

        .PARAMETER DiskNumber
            Specifies the disk number that you wish to provision the Windows image.

        .PARAMETER UEFI
            Specifies UEFI (GPT) firmware layout.

            When creating a Hyper-V boot VHD, note that generation 1 VMs require BIOS (MBR) images, and 
            generation 2 VMs require UEFI (GPT) images.

        .PARAMETER WindowsToGo
            Deploys using the "Windows To Go" layout, which should boot on both UEFI or BIOS.
            
            Windows To Go is not technically supported (upgrade path has been deprecated).

            You should not use this parameter with the "UEFI" switch.

        .PARAMETER Index
            Specifies the index number of a Windows image in a WIM file.

        .PARAMETER Passthru
            Specifies that the full path to the VHD(X) that is created should be
            returned on the pipeline.

        .PARAMETER BCDBoot
            By default, the version of BCDBOOT.EXE that is present in \Windows\System32
            is used. If you need to specify an alternate version, use this parameter to do so.

        .PARAMETER NativeBoot
            Specifies the purpose of the VHD(x). Select to skip creation of BCD store
            inside the VHD(x). Do not select if you want to ensure the BCD store is created 
            inside the VHD(x).

            Note that Windows on ARM/ARM64 does not support native boot. Do not use this switch 
            if you are provisioning an ARM/ARM64 image.

        .PARAMETER EnableDebugger
            Configures kernel debugging for the VHD(X) being created.
            EnableDebugger takes a single argument which specifies the debugging transport to use.
            Valid transports are: None, Serial, 1394, USB, Network, Local.

            Depending on the type of transport selected, additional configuration parameters will become
            available.

            Serial:
                -ComPort   - The COM port number to use while communicating with the debugger.
                             The default value is 1 (indicating COM1).
                -BaudRate  - The baud rate (in bps) to use while communicating with the debugger.
                             The default value is 115200, valid values are:
                             9600, 19200, 38400, 56700, 115200

            1394:
                -Channel   - The 1394 channel used to communicate with the debugger.
                             The default value is 10.

            USB:
                -Target    - The target name used for USB debugging.
                             The default value is "debugging".

            Network:
                -IPAddress - The IP address of the debugging host computer.
                -Port      - The port on which to connect to the debugging host.
                             The default value is 50000, with a minimum value of 49152.
                -Key       - The key used to encrypt the connection. Only [0-9] and [a-z] are allowed.
                -NoDHCP    - Prevents the use of DHCP to obtain the target IP address.
                -Newkey    - Specifies that a new encryption key should be generated for the connection.

        .PARAMETER ScratchDirectory
            Refer to the documentation of this parameter for the command 'Expand-WindowsImage' and 
            'Get-WindowsImage'.

        .PARAMETER WIMBoot
            Refer to the documentation of this parameter for the command 'Expand-WindowsImage' and 
            'Get-WindowsImage'.

        .PARAMETER Compact
            Refer to the documentation of this parameter for the command 'Expand-WindowsImage' and 
            'Get-WindowsImage'.

        .PARAMETER LogLevel
            Refer to the documentation of this parameter for the command 'Expand-WindowsImage' and 
            'Get-WindowsImage'.

        .PARAMETER LogPath
            The default is "%WINDIR%\Logs\Dism\provisioning.log".

            This command depends on the dism cmdlets 'Expand-WindowsImage' and 'Get-WindowsImage', which uses 
            different log paths.

        .EXAMPLE
            Install-WindowsImage -ImagePath D:\foo\install.wim -Index 1 -VHDPath D:\vhds\foo.vhd -UEFI:$false

            DESCRIPTION
            -----------
            Provisions a Windows image in "D:\foo\install.wim" at index position 1 to the VHD located at 
            "D:\vhds\foo.vhd".

            The VHD will be bootable only on BIOS (Generation 1) VMs.

        .EXAMPLE
            Install-WindowsImage -ImagePath D:\foo\install.wim -Index 1 -VHDPath D:\vhds\foo2.vhd

            DESCRIPTION
            -----------
            The same as Example #1, but this VHD is bootable on UEFI (generation 2) VMs.

        .EXAMPLE
            Install-WindowsImage -ImagePath D:\foo\install.wim -Index 1 -VHDPath D:\vhds\foo3.vhd -NativeBoot

            DESCRIPTION
            -----------
            The same as Example #1, but this VHD is not bootable. You can add this VHD to your boot manager, and use 
            the NativeBoot feature to boot your bare metal machine off this VHD.

        .EXAMPLE
            Install-WindowsImage -ImagePath D:\foo\install.wim -Index 1 -DiskNumber 0 -UEFI

            DESCRIPTION
            -----------
            Installs the Windows image onto a hard drive at disk number 0. The UEFI/GPT layout will be used.

        .EXAMPLE
            Install-WindowsImage -ImagePath D:\foo\install.swm -Index 1 -DiskNumber 0 -UEFI

            DESCRIPTION
            -----------
            Installs the Windows image in the SWM format. The split image files should be named "D:\foo\install.swm", 
            "D:\foo\install1.swm", "D:\foo\install2.swm", etc.

        .EXAMPLE
            Install-WindowsImage -ImagePath D:\foo\install.wim -Index 1 -VHDPath D:\vhds\foo4.vhd -EnableDebugger Serial -ComPort 2 -BaudRate 38400

            DESCRIPTION
            -----------
            Serial debugging will be enabled in the VHD via COM2 at a baud rate of 38400bps.
    #>

    #Requires -Version 3.0

    [CmdletBinding(DefaultParameterSetName = "ApplyToVHD",
        HelpURI = "https://buildcenter.github.io/windowstools/install-windowsimage")]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({ 
            (Test-Path $(Resolve-Path $_) -PathType Leaf) -and
            (($_ -like '*.wim') -or ($_ -like '*.swm'))
        })]
        [string]$ImagePath,

        [Parameter(Mandatory = $true)]
        [uint32]$Index,

        [Parameter(Mandatory = $true, ParameterSetName = 'ApplyToVHD')]
        [ValidateScript({ 
            (Test-Path $(Resolve-Path $_) -PathType Leaf) -and
            (($_ -like '*.vhd') -or ($_ -like '*.vhdx'))
        })]
        [string]$VHDPath,

        [Parameter(Mandatory = $true, ParameterSetName = "ApplyToPhysicalDisk")]
        [ValidateRange(0, 64)]
        [int]$DiskNumber,

        [Parameter()]
        [switch]$UEFI = $true,

        [Parameter()]
        [switch]$WindowsToGo,

        [Parameter(ParameterSetName = 'ApplyToVHD')]
        [switch]$NativeBoot,

        [Parameter()]
        [string]$BCDBoot = 'bcdboot.exe',

        [Parameter()]
        [ValidateSet('None', 'Serial', '1394', 'USB', 'Local', 'Network')]
        [string]$EnableDebugger = 'None',

        [Parameter()]
        [switch]$WIMBoot,

        [Parameter()]
        [switch]$Compact,

        [Parameter()]
        [ValidateSet('Errors', 'Warnings', 'WarningsInfo')]
        [string]$LogLevel,

        [Parameter()]
        [string]$ScratchDirectory,

        [Parameter()]
        [string]$LogPath = (Join-Path $env:windir -ChildPath 'Logs\Dism\provisioning.log'),

        [Parameter()]
        [Switch]$Passthru
    )

    DynamicParam
    {
        Set-StrictMode -Version 3

        # Set up the dynamic parameters.
        # Dynamic parameters are only available if certain conditions are met, so they'll only show up
        # as valid parameters when those conditions apply.  Here, the conditions are based on the value of
        # the EnableDebugger parameter.  Depending on which of a set of values is the specified argument
        # for EnableDebugger, different parameters will light up, as outlined below.

        $paramDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        if (-not (Test-Path Variable:Private:EnableDebugger))
        {
            return $paramDic
        }

        switch ($EnableDebugger)
        {
            "Serial"
            {
                # ComPort

                $comPortAttr                   = New-Object System.Management.Automation.ParameterAttribute
                $comPortAttr.ParameterSetName  = "__AllParameterSets"
                $comPortAttr.Mandatory         = $false
                $comPortValidator              = New-Object System.Management.Automation.ValidateRangeAttribute(1, 10)   # Is that a good maximum?
                $comPortNotNull                = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

                $comPortAttrCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $comPortAttrCollection.Add($comPortAttr)
                $comPortAttrCollection.Add($comPortValidator)
                $comPortAttrCollection.Add($comPortNotNull)

                $comPort                       = New-Object System.Management.Automation.RuntimeDefinedParameter("ComPort", [uint16], $comPortAttrCollection)
                $comPort.Value                 = 1  # By default, use COM1
                $paramDic.Add("ComPort", $comPort)

                # BaudRate

                $baudRateAttr                  = New-Object System.Management.Automation.ParameterAttribute
                $baudRateAttr.ParameterSetName = "__AllParameterSets"
                $baudRateAttr.Mandatory        = $false
                $baudRateValidator             = New-Object System.Management.Automation.ValidateSetAttribute(
                                                    9600, 19200,38400, 57600, 115200
                                                 )
                $baudRateNotNull               = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

                $baudRateAttrCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $baudRateAttrCollection.Add($baudRateAttr)
                $baudRateAttrCollection.Add($baudRateValidator)
                $baudRateAttrCollection.Add($baudRateNotNull)

                $baudRate = New-Object System.Management.Automation.RuntimeDefinedParameter("BaudRate", [uint32], $BaudRateAttrCollection)
                $baudRate.Value = 115200  # By default, use 115,200.
                $paramDic.Add("BaudRate", $baudRate)

                break
            }

            "1394"
            {
                $channelAttr                   = New-Object System.Management.Automation.ParameterAttribute
                $channelAttr.ParameterSetName  = "__AllParameterSets"
                $channelAttr.Mandatory         = $false
                $channelValidator              = New-Object System.Management.Automation.ValidateRangeAttribute(0, 62)
                $channelNotNull                = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

                $channelAttrCollection         = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $channelAttrCollection.Add($channelAttr)
                $channelAttrCollection.Add($channelValidator)
                $channelAttrCollection.Add($channelNotNull)

                $channel = New-Object System.Management.Automation.RuntimeDefinedParameter("Channel", [uint16], $channelAttrCollection)
                $channel.Value = 10 # By default, use channel 10
                $paramDic.Add("Channel", $channel)

                break
            }

            "USB"
            {
                $targetAttr                    = New-Object System.Management.Automation.ParameterAttribute
                $targetAttr.ParameterSetName   = "__AllParameterSets"
                $targetAttr.Mandatory          = $false
                $targetNotNull                 = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

                $targetAttrCollection          = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $targetAttrCollection.Add($targetAttr)
                $targetAttrCollection.Add($targetNotNull)

                $target = New-Object System.Management.Automation.RuntimeDefinedParameter("Target", [string], $targetAttrCollection)
                $target.Value = "Debugging"  # By default, use target = "debugging"
                $paramDic.Add("Target", $target)

                break
            }

            "Network"
            {
                # IP

                $ipAttr                        = New-Object System.Management.Automation.ParameterAttribute
                $ipAttr.ParameterSetName       = "__AllParameterSets"
                $ipAttr.Mandatory              = $true
                $ipValidator                   = New-Object System.Management.Automation.ValidatePatternAttribute(
                                                    "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
                                                 )
                $ipNotNull                     = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

                $ipAttrCollection              = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $ipAttrCollection.Add($ipAttr)
                $ipAttrCollection.Add($ipValidator)
                $ipAttrCollection.Add($ipNotNull)

                $ip = New-Object System.Management.Automation.RuntimeDefinedParameter("IPAddress", [string], $ipAttrCollection)

                $paramDic.Add("IPAddress", $ip)  # let's not set a default for ip

                # Port

                $portAttr                      = New-Object System.Management.Automation.ParameterAttribute
                $portAttr.ParameterSetName     = "__AllParameterSets"
                $portAttr.Mandatory            = $false
                $portValidator                 = New-Object System.Management.Automation.ValidateRangeAttribute(49152, 50039)
                $portNotNull                   = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

                $portAttrCollection            = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $portAttrCollection.Add($portAttr)
                $portAttrCollection.Add($portValidator)
                $portAttrCollection.Add($portNotNull)

                $port = New-Object System.Management.Automation.RuntimeDefinedParameter("Port", [uint16], $portAttrCollection)
                $port.Value = 50000  # By default, use port 50000
                $paramDic.Add("Port", $port)

                # Key

                $keyAttr                       = New-Object System.Management.Automation.ParameterAttribute
                $keyAttr.ParameterSetName      = "__AllParameterSets"
                $keyAttr.Mandatory             = $true
                $keyValidator                  = New-Object System.Management.Automation.ValidatePatternAttribute(
                                                    "\b([A-Z0-9]+).([A-Z0-9]+).([A-Z0-9]+).([A-Z0-9]+)\b"
                                                 )
                $keyNotNull                    = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute
                
                $keyAttrCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $keyAttrCollection.Add($keyAttr)
                $keyAttrCollection.Add($keyValidator)
                $keyAttrCollection.Add($keyNotNull)

                $key = New-Object System.Management.Automation.RuntimeDefinedParameter("Key", [string], $keyAttrCollection)

                $paramDic.Add("Key", $Key)  # Don't set a default key.

                # NoDHCP

                $noDhcpAttr                    = New-Object System.Management.Automation.ParameterAttribute
                $noDhcpAttr.ParameterSetName   = "__AllParameterSets"
                $noDhcpAttr.Mandatory          = $false

                $noDhcpAttrCollection          = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $noDhcpAttrCollection.Add($noDhcpAttr)

                $noDhcp = New-Object System.Management.Automation.RuntimeDefinedParameter("NoDHCP", [switch], $noDhcpAttrCollection)

                $paramDic.Add("NoDHCP", $noDhcp)

                # NewKey

                $newKeyAttr                    = New-Object System.Management.Automation.ParameterAttribute
                $newKeyAttr.ParameterSetName   = "__AllParameterSets"
                $newKeyAttr.Mandatory          = $false

                $newKeyAttrCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $newKeyAttrCollection.Add($newKeyAttr)

                $newKey = New-Object System.Management.Automation.RuntimeDefinedParameter("NewKey", [switch], $newKeyAttrCollection)

                # Don't set a default key.
                $paramDic.Add("NewKey", $newKey)

                break
            }

            # There's nothing to do for local debugging.
            # Synthetic debugging is not yet implemented.

            default
            {
               break
            }
        }

        return $paramDic
    }

    Begin
    {
        ##########################################################################################
        #                             Constants and Pseudo-Constants
        ##########################################################################################
        $PARTITION_STYLE_MBR    = 0x00000000                                   # The default value
        $PARTITION_STYLE_GPT    = 0x00000001                                   # Just in case...

        $VHD_MAXSIZE             = 2040GB                                       # Maximum size for VHD is ~2040GB.
        $VHDX_MAXSIZE            = 64TB                                         # Maximum size for VHDX is ~64TB.

        $isTranscripting         = $false


        # assert admin
        $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
        $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

        if (-not $isAdmin)
        {
            throw "This command requires administrative privileges. Launch PowerShell in an elevated session and try again."
        }
    }

    Process
    {
        if ($env:PROCESSOR_ARCHITEW6432)
        {
            throw "This command does not support running from a WoW process."
        }

        $winPEMode = $false
        $hyperVEnabled = $true
        $osBuildNumber = [int]((Get-WmiObject -Class Win32_OperatingSystem).BuildNumber)

        if (Get-Command Get-WindowsOptionalFeature -ErrorAction SilentlyContinue)
        {
            try
            {
                $hyperVFeature = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V"
                $hyperVEnabled = $hyperVFeature -and ($hyperVFeature.State -eq "Enabled")
            }
            catch
            {
                # WinPE DISM does not support online queries. This will throw on non-WinPE machines
                $winpeVersion = (Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\WinPE').Version
                Write-Verbose ("Switching to bare metal servicing mode (Windows PE version {0})" -f $winpeVersion)
                $hyperVEnabled = $false
                $winPEMode = $true
            }

            if ($hyperVEnabled -eq $true)
            {
                Write-Verbose ("Hyper-V feature detected.")
            }
        }
        else
        {
            $hyperVEnabled = $false
            Write-Verbose ("Switching to non-hypervisor mode")
        }

        $disk = $null

        try
        {
            # Log path
            if (Test-Path $LogPath)
            {
                if (Test-Path $LogPath -PathType Container)
                {
                    throw ("The log path already exists as a directory. Specify a file path and try again: {0}" -f $LogPath)
                }

                $currentLogFile = Get-Item $LogPath
                $backupLogPath = Join-Path $currentLogFile.Directory.FullName -ChildPath ($currentLogFile.BaseName + '.bak')

                Write-Verbose ("Backing up previous log file: {0} -> {1}" -f $LogPath, ($currentLogFile.BaseName + '.bak'))
                if (Test-Path $backupLogPath)
                {
                    Write-Verbose ("Overwriting previous log file.")
                    del $backupLogPath -Force
                }

                copy $LogPath $backupLogPath

            }
            else
            {
                $logParentPath = Split-Path $LogPath -Parent
                if (-not (Test-Path $logParentPath))
                {
                    Write-Verbose ("Creating directory {0}" -f $logParentPath)
                    md $logParentPath -Force | Out-Null
                }
            }

            # Try to start transcripting. If it's already running, we'll get an exception and swallow it.
            try
            {
                $null = Start-Transcript -Path $LogPath -Force -ErrorAction SilentlyContinue
                $isTranscripting = $true
            }
            catch
            {
                Write-Warning "Transcription is already running. No specific transcript will be created by this command."
                $isTranscripting = $false
            }

            # Check $ImagePath
            if (($ImagePath -like '*.wim') -or ($ImagePath -like '*.swm'))
            {
                $ImagePath  = Resolve-Path $ImagePath | select -expand Path

                if ($ImagePath -like '*.wim')
                {
                    Write-Verbose "Analyzing WIM file..."
                }
                else
                {
                    Write-Verbose "Analyzing split WIM file..."
                }

                $getWindowsImageParams = @{
                    ImagePath = $ImagePath
                    Index = $Index
                }
                if ($LogLevel) { $getWindowsImageParams.LogLevel = $LogLevel }
                if ($ScratchDirectory) { $getWindowsImageParams.ScratchDirectory = $ScratchDirectory }

                $wimInfo = Get-WindowsImage @getWindowsImageParams

                if (-not $wimInfo)
                {
                    if ($ImagePath -like '*.wim')
                    {
                        throw ("The file '{0}' is not a valid splitted WIM image, or does not contain image index #{1}. You can use the command 'Get-WindowsImage' to analyze the file." -f $ImagePath, $Index)
                    }
                    else
                    {
                        throw ("The file '{0}' is not a valid WIM image, or does not contain image index #{1}. You can use the command 'Get-WindowsImage' to analyze the file." -f $ImagePath, $Index)
                    }
                }
            }
            else
            {
                throw "Windows image files must end with the extension '.wim'"
            }

            Write-Verbose ("Selected image at index #{0}" -f $Index)

            # Create VHD if necessary
            if ($PSCmdlet.ParameterSetName -eq 'ApplyToPhysicalDisk')
            {
                $disk = Get-Disk -Number $DiskNumber
            }
            elseif ($hyperVEnabled)
            {
                Write-Verbose ("Mounting VHD")
                $disk = Get-VHD -Path $VHDPath | Mount-VHD -PassThru | Get-Disk
            }
            else
            {
                # Attach the VHD.
                Write-Verbose ("Mounting VHD")
                $disk = Mount-DiskImage -ImagePath $VHDPath -PassThru | Get-DiskImage | Get-Disk
            }

            # disk may have data
            try
            {
                if ($winPEMode -eq $true)
                {
                    Write-Verbose "Running diskpart..."

                    # fallback to diskpart
                    $diskpartScriptPath = Join-Path $env:TEMP -ChildPath 'diskpart.scp'
                    (@(
                        'select disk {0}' -f $disk.Number
                        'clean'
                    ) -join [Environment]::NewLine) | Set-Content -Path $diskpartScriptPath

                    Start-Process diskpart -ArgumentList "/s $diskpartScriptPath" -Wait -NoNewWindow
                }
                else
                {
                    Clear-Disk -Number $disk.Number -RemoveData -RemoveOEM -Confirm:$false
                }
            }
            catch
            {
                Write-Verbose "Disk cannot be cleared. It may already be uninitialized."
            }

            # Initialize depending on BIOS or UEFI
            if ($UEFI)
            {
                Write-Verbose 'Initializing disk using UEFI/GPT layout...'
                Initialize-Disk -Number $disk.Number -PartitionStyle GPT

                if ($osBuildNumber -ge 10240)
                {
                    # Create the system partition.  Create a data partition so we can format it, then change to ESP
                    Write-Verbose "Creating EFI system partition on disk"
                    $systemPartition = New-Partition -DiskNumber $disk.Number -Size 200MB -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'

                    Write-Verbose "Formatting system volume on disk"
                    $systemVolume = Format-Volume -Partition $systemPartition -FileSystem FAT32 -Force -Confirm:$false

                    Write-Verbose "Setting system partition on disk as ESP"
                    $systemPartition | Set-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
                    $systemPartition | Add-PartitionAccessPath -AssignDriveLetter
                }
                else
                {
                    # Create the system partition
                    Write-Verbose "Creating EFI system partition (ESP) on disk"
                    $systemPartition = New-Partition -DiskNumber $disk.Number -Size 200MB -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -AssignDriveLetter

                    Write-Verbose "Formatting disk ESP"
                    # Q - quick; Y - no prompt
                    format "$($systemPartition.DriveLetter):" /FS:FAT32 /Q /Y
                }

                # Create the reserved partition
                Write-Verbose "Creating MSR partition on disk"
                $reservedPartition = New-Partition -DiskNumber $disk.Number -Size 128MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'

                # Create the Windows partition
                Write-Verbose "Creating windows partition on disk"
                $windowsPartition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'

                Write-Verbose "Formatting windows volume on disk"
                $windowsVolume = Format-Volume -Partition $windowsPartition -FileSystem NTFS -Force -Confirm:$false
            }
            else
            {
                Write-Verbose "Initializing disk using legacy BIOS/MBR layout..."
                Initialize-Disk -Number $disk.Number -PartitionStyle MBR

                if ($WindowsToGo)
                {
                    Write-Warning "The Windows To Go layout has been deprecated."

                    Write-Verbose "Initializing disk..."
                    Initialize-Disk -Number $disk.Number -PartitionStyle MBR

                    # Create the system partition
                    Write-Verbose "Creating system partition on disk"
                    $systemPartition = New-Partition -DiskNumber $disk.Number -Size 350MB -MbrType FAT32 -IsActive

                    Write-Verbose "Formatting system volume on disk"
                    $systemVolume = Format-Volume -Partition $systemPartition -FileSystem FAT32 -Force -Confirm:$false

                    # Create the Windows partition
                    Write-Verbose "Creating windows partition on disk"
                    $windowsPartition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -MbrType IFS

                    Write-Verbose "Formatting windows volume on disk"
                    $windowsVolume = Format-Volume -Partition $windowsPartition -FileSystem NTFS -Force -Confirm:$false
                }
                else
                {
                    # Create the Windows/system partition
                    Write-Verbose "Creating system/Windows partition on disk"
                    $systemPartition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -MbrType IFS -IsActive
                    $windowsPartition = $systemPartition

                    Write-Verbose "Formatting windows volume on disk"
                    $systemVolume = Format-Volume -Partition $systemPartition -FileSystem NTFS -Force -Confirm:$false
                    $windowsVolume = $systemVolume
                }
            }

            # Assign drive letter to Windows partition.  This is required for bcdboot
            $windowsPartition | Add-PartitionAccessPath -AssignDriveLetter
            $windowsDrive = $(Get-Partition -Volume $windowsVolume).AccessPaths[0].Substring(0, 2)
            Write-Verbose "Temporarily mounted image Windows volume to the host at $windowsDrive"

            # Refresh access paths (we have now formatted the volume)
            $systemPartition = $systemPartition | Get-Partition
            $systemDrive = $systemPartition.AccessPaths[0].TrimEnd("\").Replace("\?", "??")
            Write-Verbose "Temporarily mounted image system volume to the host at $systemDrive"

            # don't touch this. Get-PSDrive refresh powershell provider info. Without this things may break later.
            Write-Verbose ("Global drive usage on host: {0}" -f ((Get-PSDrive -PSProvider FileSystem | select -expand Name) -join ', '))

            ####################################################################################################
            # APPLY IMAGE FROM WIM TO THE NEW VHD/DISK
            ####################################################################################################

            Write-Verbose "Applying image to disk. This can take a while..."
            $expandWindowsImageParams = @{
                ApplyPath = $windowsDrive
                ImagePath = $ImagePath
                Index = $Index
                WIMBoot = $WIMBoot
                Compact = $Compact
            }

            if ($ImagePath -like '*.swm')
            {
                $imagePathInfo = Get-Item $ImagePath
                $splitImageFilePattern = Join-Path $imagePathInfo.Directory.FullName -ChildPath ('{0}*{1}' -f $imagePathInfo.BaseName, $imagePathInfo.Extension)

                Write-Verbose "Split SWM pattern is '$splitImageFilePattern'"
                $expandWindowsImageParams."SplitImageFilePattern" = $splitImageFilePattern
            }

            if ($ScratchDirectory) { $expandWindowsImageParams.ScratchDirectory = $ScratchDirectory }
            if ($LogLevel) { $expandWindowsImageParams.LogLevel = $LogLevel }

            Expand-WindowsImage @expandWindowsImageParams

            #
            # User asked for a non-bootable image.
            #
            if (($PSCmdlet.ParameterSetName -eq 'ApplyToPhysicalDisk') -or (-not $NativeBoot))
            {
                if (Test-Path "$($systemDrive)\boot\bcd")
                {
                    Write-Warning "Image already has BIOS BCD store"
                }
                elseif (Test-Path "$($systemDrive)\efi\microsoft\boot\bcd")
                {
                    Write-Warning "Image already has EFI BCD store"
                }
                else
                {
                    Write-Verbose ("Installing boot manager with {0}" -f $BCDBoot)
                    $bcdBootArgs = @(
                        "$($windowsDrive)\Windows", # Path to the \Windows on the VHD
                        "/s $systemDrive",          # Specifies the volume letter of the drive to create the \BOOT folder on.
                        "/v"                        # Enabled verbose logging.
                    )

                    if ($UEFI)
                    {
                        $bcdBootArgs += "/f UEFI"   # Specifies the firmware type of the target system partition
                    }
                    else
                    {
                        if ($WindowsToGo)
                        {
                            # Create entries for both UEFI and BIOS if possible
                            if (Test-Path "$($windowsDrive)\Windows\boot\EFI\bootmgfw.efi")
                            {
                                $bcdBootArgs += "/f ALL"
                            }
                        }
                        else
                        {
                            $bcdBootArgs += "/f BIOS"   # Specifies the firmware type of the target system partition
                        }
                    }

                    Start-Process $BCDBoot -ArgumentList $bcdBootArgs -NoNewWindow -Wait

                    # The following is added to mitigate the VMM diff disk handling
                    # We're going to change from MBRBootOption to LocateBootOption.

                    if ((-not $UEFI) -and (-not $WindowsToGo))
                    {
                        Write-Verbose "Fixing the Device ID in the BCD store"

                        Start-Process 'bcdedit.exe' -ArgumentList @(
                            "/store $($systemDrive)\boot\bcd"
                            '/set {bootmgr} device locate'
                        ) -NoNewWindow -Wait
                        Start-Process 'bcdedit.exe' -ArgumentList @(
                            "/store $($systemDrive)\boot\bcd"
                            '/set {default} device locate'
                        ) -NoNewWindow -Wait
                        Start-Process 'bcdedit.exe' -ArgumentList @(
                            "/store $($systemDrive)\boot\bcd"
                            '/set {default} osdevice locate'
                        ) -NoNewWindow -Wait
                    }
                }

                Write-Verbose "System drive on the target disk is now bootable."

                # Are we turning the debugger on?
                if ($EnableDebugger -ne "None")
                {
                    $bcdEditArgs = $null

                    # Configure the specified debugging transport and other settings.
                    switch ($EnableDebugger)
                    {
                        "Serial"
                        {
                            $bcdEditArgs = @(
                                "/dbgsettings SERIAL",
                                "DEBUGPORT:$($ComPort.Value)",
                                "BAUDRATE:$($BaudRate.Value)"
                            )
                        }

                        "1394"
                        {
                            $bcdEditArgs = @(
                                "/dbgsettings 1394",
                                "CHANNEL:$($Channel.Value)"
                            )
                        }

                        "USB"
                        {
                            $bcdEditArgs = @(
                                "/dbgsettings USB",
                                "TARGETNAME:$($Target.Value)"
                            )
                        }

                        "Local"
                        {
                            $bcdEditArgs = @(
                                "/dbgsettings LOCAL"
                            )
                        }

                        "Network"
                        {
                            $bcdEditArgs = @(
                                "/dbgsettings NET",
                                "HOSTIP:$($IP.Value)",
                                "PORT:$($Port.Value)",
                                "KEY:$($Key.Value)"
                            )
                        }
                    }

                    $bcdStores = @(
                        "$($systemDrive)\boot\bcd",
                        "$($systemDrive)\efi\microsoft\boot\bcd"
                    )

                    foreach ($bcdStore in $bcdStores)
                    {
                        if (Test-Path $bcdStore)
                        {
                            Write-Verbose "Enabling kernel debugging for BCD store: $bcdStore"

                            Start-Process 'bcdedit.exe' -ArgumentList @(
                                "/store $bcdStore"
                                '/set {default} debug on'
                            ) -NoNewWindow -Wait

                            $bcdEditArguments = @("/store $bcdStore") + $bcdEditArgs

                            Start-Process 'bcdedit.exe' -ArgumentList $bcdEditArguments -NoNewWindow -Wait
                        }
                    }
                }
            }
            else
            {
                # Don't bother to check on debugging.  We can't boot WoA VHDs in VMs, and
                # if we're native booting, the changes need to be made to the BCD store on the
                # physical computer's boot volume.

                Write-Verbose "The boot manager was not installed on the target disk (using NativeBoot)"
            }

            # Label the windows drive
            Write-Verbose "Labelling Windows drive on disk"
            $windrv = gwmi win32_volume -Filter "DriveLetter = '$windowsDrive'"
            $windrv.Label = 'Windows'
            $windrv.Put()

            #
            # Remove system partition access path, if necessary
            #
            if ($UEFI)
            {
            
                Write-Verbose "A temporary ESP partition access path on the disk was mounted on the host. Removing it now."
                $systemPartition | Remove-PartitionAccessPath -AccessPath $systemPartition.AccessPaths[0]
            }

            if ($PSCmdlet.ParameterSetName -eq 'ApplyToVHD')
            {
                Write-Verbose "Dismounting VHD: $VHDPath"

                if ($hyperVEnabled)
                {
                    Dismount-VHD -Path $VHDPath
                }
                else
                {
                    Dismount-DiskImage -ImagePath $VHDPath
                }
            }
        }
        catch
        {
            Write-Error $_
            Write-Verbose "See log file at $LogPath"
        }
        finally
        {
            # If VHD is mounted, unmount it
            if (($PSCmdlet.ParameterSetName -eq 'ApplyToVHD') -and (Test-Path $VHDPath))
            {
                if ($hyperVEnabled)
                {
                    if ((Get-VHD -Path $VHDPath).Attached)
                    {
                        Write-Verbose "VHD is still mounted. Dismounting: $VHDPath"
                        Dismount-VHD -Path $VHDPath
                    }
                }
                else
                {
                    Write-Verbose "Attempting to dismount VHD: $VHDPath"
                    Dismount-DiskImage -ImagePath $VHDPath
                }
            }

            # Close out the transcript and tell the user we're done.

            if ($isTranscripting)
            {
                Write-Verbose "Stopping transcription"
                Stop-Transcript | Out-Null
            }

            Write-Verbose "All done."
        }
    }

    End
    {
        if (($PSCmdlet.ParameterSetName -eq 'ApplyToVHD') -and $Passthru)
        {
            Get-Item $VHDPath
        }
        elseif (($PSCmdlet.ParameterSetName -eq 'ApplyToPhysicalDisk') -and $Passthru)
        {
            Get-Disk -Number $DiskNumber
        }
    }
}
