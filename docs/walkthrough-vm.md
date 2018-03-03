Walkthrough
===========
Congrats for completing [the walkthrough](./walkthrough.md)! We are here to deploy your image to a VM for Hyper-V.

You need to install Hyper-V on your Windows PC to complete this walkthrough.


Creating a VHD
--------------
This VHD will be used to boot your VM. Run Powershell with administrative privileges and type the following:

```powershell
Set-ExecutionPolicy Unrestricted
New-VHD -Path C:\WindowsBuilder\working\output\Win10.vhdx -SizeBytes 64GB -Dynamic
ipmo C:\WindowsBuilder\provisioning\WindowsProvisioning.psm1
Install-WindowsImage -ImagePath C:\WindowsBuilder\working\output\install.wim -Index 3 -VHDPath C:\WindowsBuilder\working\output\Win10.vhdx -UEFI -Verbose
```


Create a differencing VHD
-------------------------
Installing a Windows image to VHD can take some time. Let's create a differencing VHD to play with, so the original VHD is never touched:

```powershell
New-VHD -Path C:\WindowsBuilder\working\output\win10-sub.vhdx -ParentPath C:\WindowsBuilder\working\output\win10.vhdx -Differencing
```


Preboot Customization
---------------------
Use `/provisioning/customizer.ps1` to generate `oemcustom.json` and `unattend.xml`. Then copy the files:

```powershell
. C:\WindowsBuilder\provisioning\customizer.ps1
# Answer the questions
Mount-VHD -Path C:\WindowsBuilder\working\output\Win10-sub.vhdx

# Take note of the mounted Windows drive! The script below assumes I:
copy C:\WindowsBuilder\provisioning\oemcustom.json I:\Windows\Setup\Scripts\ -Force
copy C:\WindowsBuilder\provisioning\unattend.xml I:\Windows\System32\Sysprep\ -Force
Dismount-VHD -Path C:\WindowsBuilder\working\output\Win10-sub.vhdx
```


Deploy to VM
------------
Create a generation 2 VM on Hyper-V, using `C:\WindowsBuilder\working\output\win10-sub.vhdx` as the boot disk.

Start the VM and voila!


Optimization for Production
---------------------------
You should always use a fixed VHD when running in production mode. Dynamic VHD has very lousy I/O speed because it needs to expand dynamically.

You shouldn't use a differencing disk either. Copy the reference VHD out entirely as a new VHD.

```powershell
New-VHD -Path C:\WindowsBuilder\working\output\Win10.vhdx -SizeBytes 64GB -Fixed
# ...
New-VHD -Path C:\WindowsBuilder\working\output\Win10-sub.vhdx -ParentPath C:\WindowsBuilder\working\output\win10.vhdx
```

Of course, this takes more time and disk space.
