#!/usr/bin/env bash
echo -ne "
-------------------------------------------------------------------------
#          _____               _          _             _     
#         |  ___|__ _ __  _ __(_)___     / \   _ __ ___| |__  
#         | |_ / _ \ '_ \| '__| / __|   / _ \ | '__/ __| '_ \ 
#         |  _|  __/ | | | |  | \__ \  / ___ \| | | (__| | | |
#         |_|  \___|_| |_|_|  |_|___/ /_/   \_\_|  \___|_| |_|
#                                                     
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
                        Scripthome: ${SCRIPTHOME}
-------------------------------------------------------------------------
"
source /root/$SCRIPTHOME/setup.conf
source /root/$SCRIPTHOME/functions.sh
echo -ne "
-------------------------------------------------------------------------
                    Network Setup 
-------------------------------------------------------------------------
"
pacmanInstall networkmanager dhclient
systemctl enable --now NetworkManager
echo -ne "
-------------------------------------------------------------------------
                    Setting up mirrors for optimal download 
-------------------------------------------------------------------------
"
pacmanInstall pacman-contrib curl
pacmanInstall reflector rsync grub git rustup zsh

echo -ne "
-------------------------------------------------------------------------
                    You have " $nc" cores. And
			changing the makeflags for "$nc" cores. Aswell as
				changing the compression settings.
-------------------------------------------------------------------------
"
setMakeAndCompress || errorAndExit "Error Setting Make Cores"

echo -ne "
-------------------------------------------------------------------------
                    Setup Language to US and set locale
                         new timezone: ${TIMEZONE}
                           new keymap: ${KEYMAP}
-------------------------------------------------------------------------
"
setLocale || errorAndExit "Setting Locale"

sudoNoPw || errorAndExit "Enabling sudo no pw"

pacmanActivateParallelDl || errorAndExit "Activating parallel downloads"
pacmanEnableMultilib || errorAndExit "Enabling Multilib"

installOpenBuildSystem || errorAndExit "Enabling Open build systems"


if [[ -d "/sys/firmware/efi" ]]; then
    pacmanInstall efibootmgr
fi

echo -ne "
-------------------------------------------------------------------------
                    Installing Microcode
-------------------------------------------------------------------------
"
installMicroCode || errorAndExit "installing cpu microcode"

echo -ne "
-------------------------------------------------------------------------
                    Installing Graphics Drivers
-------------------------------------------------------------------------
"
installGpuDriver || errorAndExit "installing gpu drivers"

echo -ne "
-------------------------------------------------------------------------
                    Adding User
-------------------------------------------------------------------------
"
initUserAndMachine || errorAndExit "Creating user"

if [[ ${FS} == "luks" ]]; then
    addEncryptToMkinit || errorAndExit "Adding encrypt to kernel modules"
fi

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 2-user.sh
-------------------------------------------------------------------------
"