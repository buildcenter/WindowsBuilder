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

	$regacl = $regkey.GetAccessControl()
	$adminFullAccessRule = New-Object System.Security.AccessControl.RegistryAccessRule("BUILTIN\Administrators", "FullControl", "Allow")
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

	$acl = Get-Acl $Path
	$ownerAccount = New-Object System.Security.Principal.NTAccount("BUILTIN\Administrators")
	$acl.SetOwner($ownerAccount)
	Set-Acl -Path $Path -AclObject $acl

	$acl = Get-Acl $Path
	$adminFullAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators", "FullControl", "Allow")
	$acl.AddAccessRule($adminFullAccessRule)
	Set-Acl -Path $Path -AclObject $acl
}

