<#
-------------------------------------------------------------------
[Defaults]
These are the default configuration values. You don't have to 
specify them.
-------------------------------------------------------------------
$config.BuildFileName = "default.ps1"
$config.EnvPath = $null
$config.TaskNameFormat = "Executing {0}"
$config.VerboseError = $false
$config.ColoredOutput = $true
$config.Modules = $null

-------------------------------------------------------------------
[Modules]
You can load your custom PowerShell modules into your build session. 
Here we load all modules from the 'modules' folder and from file 
'my_module.psm1' (all relative to the build script path).
-------------------------------------------------------------------
$config.Modules = ("./modules/*.psm1", "./my_module.psm1")

-------------------------------------------------------------------
[Print Task Name]
Custom print the task name by overriding 'TaskNameFormat' with a 
scriptblock.
-------------------------------------------------------------------
$config.TaskNameFormat = { param($taskName) "Executing $taskName at $(Get-Date)" }

#>
