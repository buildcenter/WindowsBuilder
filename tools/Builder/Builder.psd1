# #####################################################################
# Module manifest for module 'Builder'
#
# Copyright (c) 2018 Lizoc Inc. All rights reserved.
#
# This is a generated file. Modifications will be lost on the next 
# generate sequence.
#
# #####################################################################

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Builder.psm1'

    # Version number of this module.
    ModuleVersion = '3.1.1024.0'

    # ID used to uniquely identify this module
    GUID = 'f611135c-e6d9-444d-a4a7-e8a15728942b'

    # Author of this module
    Author = 'Powershell Team'

    # Company or vendor of this module
    CompanyName = 'Lizoc Inc.'

    # Copyright statement for this module
    Copyright = 'Copyright (c) 2018 Lizoc Inc. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Builder is a source code build system based on PowerShell.'

    # Supported PSEditions
    # CompatiblePSEditions = ''

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module
    # DotNetFrameworkVersion = '3.5'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion = '3.5'

    # Processor architecture (None, X86, Amd64) required by this module
    ProcessorArchitecture = 'None'

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = ''

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = ''

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = ''

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = ''

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = ''

    # First load importing this module. Depreciated (use 'RootModule').
    # ModuleToProcess = ''
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = ''

    # Functions to export from this module
    # FunctionsToExport = ''

    # Cmdlets to export from this module
    # CmdletsToExport = ''

    # Variables to export from this module
    # VariablesToExport = ''

    # Aliases to export from this module
    # AliasesToExport = ''

    # DSC resources to export from this module
    # DscResourcesToExport = ''

    # List of all modules packaged with this module
    # ModuleList = ''

    # List of all files packaged with this module
    # FileList = ''

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        # PSData is module packaging and gallery metadata embedded in PrivateData
        # It's for rebuilding NuGet-style packages
        # We had to do this because it's the only place we're allowed to extend the manifest
        # https://connect.microsoft.com/PowerShell/feedback/details/421837
        PSData = @{
            # The primary categorization of this module (from the TechNet Gallery tech tree).
            Category = 'Scripting Techniques'

            # Keyword tags to help users find this module via navigations and search.
            Tags = 'powershell', 'buildtool'

            # The web address of an icon which can be used in galleries to represent this module
            IconUri = 'http://buildcenter.github.io/Builder/icon.png'

            # The web address of this module's project or support homepage.
            ProjectUri = 'http://buildcenter.github.io/Builder/'

            # The web address of this module's license. Points to a page that's embeddable and linkable.
            LicenseUri = 'http://buildcenter.github.io/Builder/LICENSE.md'

            # Release notes for this particular version of the module
            ReleaseNotes = 'http://buildcenter.github.io/Builder/RELEASENOTES.md'

            # If true, the LicenseUrl points to an end-user license (not just a source license) which requires the user agreement before use.
            RequireLicenseAcceptance = 'False'

            # Indicates this is a pre-release/testing version of the module.
            IsPrerelease = 'False'
        }

        PSExtend = @{
            # Last update
            LastUpdate = '2018-2-4'

            # License family
            LicenseFamily = 'MIT'

            # Language customization
            # Language = 'System'
        }
    }

    # HelpInfo URI of this module
    HelpInfoURI = 'http://buildcenter.github.io/Builder/README.md'

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = 
}

