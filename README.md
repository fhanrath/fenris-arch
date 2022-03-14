# FenrisArch Installer Script

This README contains the steps I do to install and configure a fully-functional Arch Linux installation containing a sway desktop, all the support packages (network, bluetooth, audio, printers, etc.), along with all my preferred applications and utilities. The shell scripts in this repo allow the entire process to be automated.)

Available on [sourcehut](https://git.sr.ht/~fenris/fenris-arch).

---
## Create Arch ISO or Use Image

Download ArchISO from <https://archlinux.org/download/> and put on a USB drive with [Etcher](https://www.balena.io/etcher/), [Ventoy](https://www.ventoy.net/en/index.html), or dd `sudo dd if=<path_to_iso> of=/dev/<usb-device> bs=1024k status=progress`.

## Boot Arch ISO

From initial Prompt type the following commands:

```
pacman -Sy git
git clone https://git.sr.ht/~fenris/fenris-arch
cd fenris-arch
./install.sh
```

### System Description
This is completely automated arch install with swaywm on arch using all the packages I use on a daily basis. 

## Troubleshooting

__[Arch Linux Installation Guide](https://github.com/rickellis/Arch-Linux-Install-Guide)__

## Credits by Fenris

- ArchTitus by ChrisTitus, MIT (original licence under LICENCE_original): <https://github.com/ChrisTitusTech/ArchTitus>
  - original Image without my changes: <https://www.christitus.com/arch-titus>

## Credits - Original by ChrisTitus

- Original packages script was a post install cleanup script called ArchMatic located here: https://github.com/rickellis/ArchMatic
- Thank you to all the folks that helped during the creation from YouTube Chat! Here are all those Livestreams showing the creation: <https://www.youtube.com/watch?v=IkMCtkDIhe8&list=PLc7fktTRMBowNaBTsDHlL6X3P3ViX3tYg>
