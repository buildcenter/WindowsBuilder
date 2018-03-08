Walkthrough
===========
Congrats for completing [the walkthrough](./walkthrough.md)! We are here to create a VHD for native boot.

Native boot is a feature of Windows Boot Manager. Instead of booting from a physical disk, you can boot your OS off a VHD file. This is almost the same as
running an OS from a regular disk.

Unfortuantely, native boot is tied to the Windows boot manager, which means no grub, and therefore you can't put a Linux system inside a VHD and boot to it.

You need to install Hyper-V on your Windows PC to complete this walkthrough.


Creating a VHD
--------------
This VHD will be used to boot your physical computer. Run Powershell with administrative privileges and type the following:

```powershell
Set-ExecutionPolicy Unrestricted
New-VHD -Path C:\WindowsBuilder\working\output\Win10.vhdx -SizeBytes 64GB -Fixed
ipmo C:\WindowsBuilder\provisioning\WindowsProvisioning.psm1
Install-WindowsImage -ImagePath C:\WindowsBuilder\working\output\install.wim -Index 3 -VHDPath C:\WindowsBuilder\working\output\Win10.vhdx -UEFI -Compact -NativeBoot -Verbose
```

This assumes that your `install.wim` has a Windows edition at index position 3, which is the one you want to install.

Windows 10 only supports native boot using the VHDX format.

Always use a fixed VHD for optimal performance. A dynamic VHD often cannot keep up with the I/O speed required by Windows, and you will get a sluggish experience, or worse still, 
mysterious bsods. Of course, this rules out creating differencing VHDs too, which by definition is always dynamic.



Preboot Customization
---------------------
Use `/provisioning/customizer.ps1` to generate `oemcustom.json` and `unattend.xml`. Then copy the files:

```powershell
. C:\WindowsBuilder\provisioning\customizer.ps1
# Answer the questions
Mount-VHD -Path C:\WindowsBuilder\working\output\Win10.vhdx

# Take note of the mounted Windows drive! The script below assumes I:
copy C:\WindowsBuilder\provisioning\oemcustom.json I:\Windows\Setup\Scripts\ -Force
copy C:\WindowsBuilder\provisioning\unattend.xml I:\Windows\System32\Sysprep\ -Force
Dismount-VHD -Path C:\WindowsBuilder\working\output\Win10.vhdx
```


Install on bare metal
---------------------
Move `C:\WindowsBuilder\working\output\Win10.vhdx` to your desired location. If you have a SSD, put your VHDX on that. It makes a very big performance difference.

For this exercise, we put it in `C:\NativeBoot\WIN10.vhdx`. To protect the VHD from accidental modification by users, we set the ACL for `C:\NativeBoot`:

```powershell
$acl = Get-Acl C:\NativeBoot
$acl.SetSecurityDescriptorSddlForm('O:S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464G:S-1-5-21-3743141187-1647405133-3778558433-513D:PAI(A;OICIIO;FA;;;CO)(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)')
$acl | Set-Acl C:\NativeBoot
```

This translates to:
```
Owner: NT SERVICE\TrustedInstaller

Access:

FileSystemRights  : FullControl
AccessControlType : Allow
IdentityReference : CREATOR OWNER
IsInherited       : False
InheritanceFlags  : ContainerInherit, ObjectInherit
PropagationFlags  : InheritOnly

FileSystemRights  : FullControl
AccessControlType : Allow
IdentityReference : NT AUTHORITY\SYSTEM
IsInherited       : False
InheritanceFlags  : ContainerInherit, ObjectInherit
PropagationFlags  : None

FileSystemRights  : FullControl
AccessControlType : Allow
IdentityReference : BUILTIN\Administrators
IsInherited       : False
InheritanceFlags  : ContainerInherit, ObjectInherit
PropagationFlags  : None
```

Next, we modify Windows Boot Manager to recognize the VHD as a boot option:

```powershell
ipmo C:\WindowsBuilder\provisioning\WindowBootManager.psm1
Get-WindowsBootRecord -Online
# You can customize your description!
$bcdId = Copy-WindowsBootRecord -Source '{current}' -Description 'Windows 10 Native Boot'
Set-WindowsBootRecord -Identifier $bcdId -Property osdevice -Value 'vhd=[locate]\NativeBoot\WIN10.vhdx'
Set-WindowsBootRecord -Identifier $bcdId -Property device -Value 'vhd=[locate]\NativeBoot\WIN10.vhdx'
```

If you want to set your native boot VHD as the first and default choice when the system boots up:

```powershell
Set-WindowsBootOrder -Default $bcdId
```

All done. When you reboot your PC, there will be a choice to boot into `Windows 10 Native Boot` (or whatever description you set before).

**TIPS** In an automated setting, it is important to set the default boot option to your new VHD. When 2 or more boot options are available, 
Windows Boot Manager will present the options in a boot menu, and if no user selection is made within the timeout period, boot to the default 
option. Therefore, you will never be able to automatically get into your native boot OS this way.

Instead, set the default boot option to your native boot VHD, and let the system reboot using the `Restart-Computer` command. Then, when you 
want to boot back to the original system, set the default boot option using the same technique (via `Set-WindowsBootOrder`), changing the identifier 
this time to the one for your original boot entry.


Uninstall
---------
To uninstall:

```powershell
ipmo C:\WindowsBuilder\provisioning\WindowBootManager.psm1
Get-WindowsBootRecord -Online
# Locate the identifier for the record you wish to remove via its description, or you can just get its identifier manually
$bcdId = Get-WindowsBootRecord -Online | where { $_.description -eq 'Windows 10 Native Boot' } | select -expand identifier
Remove-WindowsBootRecord -Identifier $bcdId
```

Don't forget to delete `C:\NativeBoot\WIN10.vhdx` too.
