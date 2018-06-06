function Get-BuiltinAdministratorsName
{
	<#
		.SYNOPSIS
			The name 'BUILTIN\Administrators' is different on non-English system. This gets the name in a culture-neutral way.
	#>

	[CmdletBinding()]
	Param()

	# S-1-5-32-544 is BUILTIN\Administrators
	# https://support.microsoft.com/en-sg/help/243330/well-known-security-identifiers-in-windows-operating-systems
	$sid = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')
	[System.Security.Principal.NTAccount]($sid.Translate([type]::GetType('System.Security.Principal.NTAccount'))) | select -expand Value
}

function Grant-AdminFullRegistryKeyAccess
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	if ($Path.StartsWith('HKCU:\'))
	{
		$regkey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($Path.Replace('HKCU:\', ''), [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::ChangePermissions)
	}
	elseif ($Path.StartsWith('HKLM:\'))
	{
		$regkey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Path.Replace('HKLM:\', ''), [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::ChangePermissions)
	}

	$adminsAccountName = Get-BuiltinAdministratorsName

	$regacl = $regkey.GetAccessControl()
	$adminFullAccessRule = New-Object System.Security.AccessControl.RegistryAccessRule($adminsAccountName, "FullControl", "Allow")
	$regacl.AddAccessRule($adminFullAccessRule)
	$regkey.SetAccessControl($regacl)
	$regkey.Dispose()
}

function Grant-AdminFullFileAccess
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	$adminsAccountName = Get-BuiltinAdministratorsName

	$acl = Get-Acl $Path
	$ownerAccount = New-Object System.Security.Principal.NTAccount($adminsAccountName)
	$acl.SetOwner($ownerAccount)
	Set-Acl -Path $Path -AclObject $acl

	$acl = Get-Acl $Path
	$adminFullAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($adminsAccountName, "FullControl", "Allow")
	$acl.AddAccessRule($adminFullAccessRule)
	Set-Acl -Path $Path -AclObject $acl
}

