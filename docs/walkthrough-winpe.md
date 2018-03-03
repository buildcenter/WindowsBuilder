Walkthrough
===========
Congrats for completing [the walkthrough](./walkthrough.md)! We are here to deploy your image to a bare metal PC.


Deploying Windows PE
--------------------
Download Windows 10 ADK from Microsoft. Follow the instructions for creating a Windows PE boot USB drive. You need to customize the image to 
include Powershell.

#todo #up_for_grabs Windows 10 PE build bsd.


Deploying Windows 10
--------------------
Copy out your customized image (*.swm) to your USB drive. Let's put them in `[USB]\osimage\` (create the folder) on your USB drive.

Copy out the `C:\WindowsBuilder\provisioning` folder to your USB too.

Boot the PC you want to service using that USB drive. You should boot into Windows PE.

Once you are in:

```powershell
powershell
Set-ExecutionPolicy Unrestricted
Get-PSDrive
# Assuming D: is the USB drive
ipmo D:\provisioning\WindowsProvisioning.psm1
Get-Disk
# Take note of the disk number of the PC's boot disk. Be very careful!
# The boot disk is normally disk 0, but double check, because that disk will be formatted.
Install-WindowsImage -ImagePath D:\osimage\surfacepro.swm -Index 3 -DiskNumber 0 -UEFI -Compact -Verbose
# The `UEFI` parameter is recommended for newer PC that supports UEFI firmware.
# The `Compact` parameter is recommended when the boot disk is a SSD.
# The `-Verbose` parameter is optional, but we want to see what it is doing for this exercise
```


Preboot Customization
---------------------
Use `[USB Drive]/provisioning/customizer.ps1` to generate `oemcustom.json` and `unattend.xml`. Then copy the files:

```powershell
. D:\provisioning\customizer.ps1
# Answer the questions

# Assuming I: is the new drive letter of the Windows volume
copy D:\provisioning\oemcustom.json I:\Windows\Setup\Scripts\ -Force
copy D:\provisioning\unattend.xml I:\Windows\System32\Sysprep\ -Force
```


Finalize deployment
-------------------
You should now unplug the USB drive from your PC.

Reboot the PC for installation to continue. The PC should reboot 3 times, finishing at the logon screen.

```powershell
Restart-Computer
```

Three accounts are created by default. The super account is an administrative account, another one with your customized name is a normal user 
account, and a `Friend` account for guest access.

Logon using the super account, using the password provided in the preboot customization stage. You can get the passwords for 2 additiona accounts 
created from `[USB drive]\provisioning\unattend.xml`, or just set new passwords for these accounts using the super account.

We recommend using the normal user account for daily work.


Optimization for Production
---------------------------
The default accounts created can be fully customized by editing the following files:

- provisioning\customizer.ps1
- provisioning\Unattend.xml.tmpl

In addition, edit the `oemcustom-ref.json` to automate the customizer. If you provide all fields in the referance JSON file, the customizer will not 
prompt for anything.
