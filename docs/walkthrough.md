Walkthrough
===========
First, you will need a *licensed* copy of the official Windows image. If you have subscribed to MSDN, you may be able to download the ISO 
from [the MSDN website](https://msdn.microsoft.com).

For the rest of this walkthrough, let's assume we are working with `en_windows_10_multi-edition_vl_version_1709_updated_sept_2017_x64_dvd_100090741.iso`.

Run command prompt with administrative privileges (start menu > command prompt > right-click > run as 'Administrator'). Run the following commands:

```batchfile
cd C:\
md WindowsBuilder && cd WindowsBuilder
powershell -Command "& { wget https://raw.githubusercontent.com/buildcenter/WindowsBuilder/master/scaffold.ps1 -UseBasicParsing | iex }
build configure
```

Obviously, for the more vigilent, you should just download this repo on Github (Clone or download > Download ZIP) and copy 
out the contents of the ZIP file to `C:\`. Don't forget to run `build configure`!

Mount your ISO and copy out the contents of `[ISO]\source\install.wim` to `C:\WindowsBuilder\working\output`.

Back to your command prompt:

```batchfile
build mount .\working\output\install.wim
```

Your WIM image probably contains multiple versions of Windows. WindowsBuilder will analyze the WIM file and prompt you to select the version to mount. We 
are using #3 (Windows Enterprise). Mounting and dismounting can take a long time, especially on magnetic hard disks. We strongly recommend doing this on a fast SSD.

Next, you will normally be making a copy of `C:\WindowsBuilder\src\global.bsd` to something meaningful. We have already made one `win10-1709.bsd`, so 
let's work with that for now. Go ahead and open `C:\WindowsBuilder\src\win10-1709.bsd` with your favorite text editor. Follow our inline documentation 
and make your changes.

Your assets lives under `C:\WindowsBuilder\resource` by default. We have made some sample resources to get you started.

When you are satisfied with your customization:

```batchfile
build win10-1709
```

Be patient and let WindowsBuilder do the legwork. Then dismount the image and save your changes:

```batchfile
build dismount
```

**TIPS** Saving a large WIM file can be very CPU and I/O intensive. Some ways to speed things up are:

- Tune up your PC power plan to high performance
- Disable antivirus active protection
- Don't run any other heavyweight process with this


Embedding drivers
-----------------
The computer that you want to service will probably include some custom third party drivers. We can embed them right in, so everything 
works right out of the box! 

We have included a sample configuration for Surface Pro 3. Go download your driver pack from [the official source](https://www.microsoft.com/en-us/download/details.aspx?id=38826). We 
have tested `SurfacePro3_Win10_14393_1703702_1.zip` with Windows 10 (1709) and it works fine. Unzip to `C:\WindowsBuilder\resource\Driver-SurfacePro3`.

Again, this repo has included a sample configuration under `src\surfacepro3.bsd`. Open it up with your favorite text editor and review the configuration. When you 
are done:

```batchfile
copy .\working\output\install.wim .\working\output\surfacepro.wim
build mount .\working\output\surfacepro.wim
build surfacepro3
build dismount
```

Sometimes your PC manufacturer doesn't provide an easy way for you to download all drivers in a complete package. In that case, install WindowsBuilder on the PC you want to service, and 
create a dump of all installed drivers:

```batchfile
build driver dump
```


Split Image
-----------
We're almost ready to install your customized image on the bare metal. If you are putting your image file on a USB drive, note that FAT32 filesystem cannot handle files bigger than 
4GB, which your final WIM may well exceed. To work around that, we recommend splitting the image to 1GB pieces:

```batchfile
build split .\working\output\surfacepro.wim
```

You will get `C:\WindowsBuilder\working\output\surfacepro.swm`, `C:\WindowsBuilder\working\output\surfacepro1.swm`, etc.


Optional
--------
You can remove unused versions in the final image. This is mostly just to reduce confusion.

```batchfile
powershell
Get-WindowsImage -Path .\working\output\install.wim
# This will remove all except entry 3
Remove-WindowsImage -Path .\working\output\install.wim -Index 1
Remove-WindowsImage -Path .\working\output\install.wim -Index 1
Remove-WindowsImage -Path .\working\output\install.wim -Index 2
Remove-WindowsImage -Path .\working\output\install.wim -Index 2
Remove-WindowsImage -Path .\working\output\install.wim -Index 2
```


Ready to Go
-----------
If you are trying to install Windows on a bare metal PC, go to the tutorial on [building your Windows PE](./walkthrough-winpe.md) USB drive.

You can also install Windows on bare metal using a VHD. This is called "native boot". Check out [the tutorial here](./walkthrough-nativeboot.md).

If your computer has Windows Hyper-V installed, and you want to install your image on a virtual machine, go to the 
tutorial on [installing WIM on VHD](./walkthrough-vm.md).
