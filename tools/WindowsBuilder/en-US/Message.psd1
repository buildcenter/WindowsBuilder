# Localized	25/12/2016 7:08 PM (GMT)	303:4.80.0411	Message.psd1
# Main LocalizedData.en-US

ConvertFrom-StringData @'

# ---- [ Localized Data ] ---------------------------------------------

#
# Help
#
LocaleName = en-US
AuthorLabel = Created by
VersionLabel = Version
Author = Build Team @Lizoc
Version = 3.1.1024.0
Syntax = SYNTAX
Example = EXAMPLE
Description = DESCRIPTION
Remarks = REMARKS
HelpTopics = OTHER HELP TOPICS
HelpTopicNotFound = [!] The help topic "{0}" is unavailable. Here are the topics we have:
Example1_1 = Perform all customizations available under "/src" on the mounted image. Configuration by default is taken from "src/global.bsd".
Example2_1 = Perform all customizations available under "/src" on the mounted image. Configuration is taken from "src/win10.bsd".
Example2_2 = An error occurs if the configuration file does not exist.
Example3_1 = Mounts an image interactively by prompting you with some questions. Automate this using the "build mount <configuration> <index>" syntax.

#
# Finish
#
Goodbye = My work here is done. Goodbye!

#
# Precheck
#
UnsupportedSubcommand = The subcommand "{0}" is not supported. Available subcommands are: {1}
ConfigurationNullOrEmpty = The property "Configuration" cannot be null or empty.
RequireRunAsAdmin = This utility requires administrative privileges.

#
# Setup
#
ImportingModules = Importing helper modules...
ImportingDefaultConfig = Importing default configuration
DefaultConfigFileNotFound = The default configuration file was not found: {0}
CustomConfigFileNotFound = The custom configuration file was not found: {0}
UsingDefaultConfig = Using default configuration because no custom configuration was specified.
ConfigPropertyNameReserved = The property name "{0}" is reserved. Do not use this property in your configuration file.
RequiredFileNotFound = A required file was not found: {0}
RequiredFolderNotFound = A required folder was not found: {0}
RemovingUnexpectedFile = Removing unexpected file in path: {0}
CreatingFolder = Creating folder: {0}
RegistryMountPointNotSpecifiedOrInvalid = The registry mount point path for "{0}" is invalid: {1}
RegistryMountPointExists = The registry mount point path already exists: {0}

#
# Discover
#
DiscoveringAvailableModules = Discovering available modules...
NotModule = The folder "src/{0}" is not a module!
ModuleCannotUseReservedName = [!] A module is using a reserved name and will be ignored: {0}

#
# Configure
#
NoModuleAvailable = Unable to find any build modules.

#
# Mount
#
PromptWimFilePath = Enter the full file path to the Windows image file (normally named "install.wim")
ReferenceImageFileNotFound = The reference Windows image file was not found: {0}
ReadingWimEntries = Analyzing WIM file content...
PromptWimImageIndex = Enter the image index of the OS version you would like to modify.
MountingImage = Mounting image {0} [#{1}] --> {2}

#
# Dismount
#
DismountDiscardChange = Dismounting image and discarding changes. This may take a while...
DismountSaveChange = Dismounting image and commiting changes. This may take a while...

#
# Driver
#
RemovingExistingDriverDump = Removing existing driver dump: {0}
DumpingDrivers = Dumping all add-on drivers to "{0}". This may take a while...

#
# Build
#
NoTargetModule = Unable to build because there is no effective targets.
StartBuildModule = Starting build module: {0}
DriverCommandNothingToDo = You need to type "build driver dump".

# ---- [ /Localized Data ] --------------------------------------------
'@
