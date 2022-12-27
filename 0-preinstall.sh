#!/usr/bin/env bash
#-------------------------------------------------------------------------
#  _____               _          _             _     
# |  ___|__ _ __  _ __(_)___     / \   _ __ ___| |__  
# | |_ / _ \ '_ \| '__| / __|   / _ \ | '__/ __| '_ \ 
# |  _|  __/ | | | |  | \__ \  / ___ \| | | (__| | | |
# |_|  \___|_| |_|_|  |_|___/ /_/   \_\_|  \___|_| |_|
#                                                     
#-------------------------------------------------------------------------
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source setup.conf
source functions.sh

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

Setting up mirrors for optimal download
"
iso=$(getIso)
testIso
timedatectl set-ntp true
pacmanInstall archlinux-keyring
pacmanInstall pacman-contrib terminus-font
setTermiusFont
pacmanActivateParallelDl || errorAndExit "activating parallel downloads"
pacmanInstall reflector rsync grub
echo -ne "
-------------------------------------------------------------------------
                    Setting up $iso mirrors for faster downloads
-------------------------------------------------------------------------
"
setupPacmanMirrors || errorAndExit "setting up pacman mirrors"
echo -ne "
-------------------------------------------------------------------------
                    Installing Prerequisites
-------------------------------------------------------------------------
"
pacmanInstall gptfdisk btrfs-progs glibc

mkdir -p /mnt
echo -ne "
-------------------------------------------------------------------------
                    Formating Disk
-------------------------------------------------------------------------
"
formatDisk || errorAndExit "formatting disk"

echo -ne "
-------------------------------------------------------------------------
                    Creating Filesystems
                    DISK: ${DISK}
                    FS: ${FS}
                    mountoptions: ${mountoptions}
-------------------------------------------------------------------------
"
if [[ "${DISK}" =~ "nvme" ]]; then
    partition2=${DISK}p2
    partition3=${DISK}p3
else
    partition2=${DISK}2
    partition3=${DISK}3
fi

if [[ "${FS}" == "btrfs" ]]; then
    formatBtrfs || errorAndExit "creating filesystem"
elif [[ "${FS}" == "luks" ]]; then
    formatLuksBtrfs || errorAndExit "creating and encrypting filesystem"
fi

mountBoot || errorAndExit "mounting boot"

if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted can not continue"
    exit
fi

echo -ne "
-------------------------------------------------------------------------
                    Checking for low memory systems <24G
                    DISABLED
-------------------------------------------------------------------------
"
setSwap || errorAndExit "setting Swap"

echo -ne "
-------------------------------------------------------------------------
                    Arch Install on Main Drive
-------------------------------------------------------------------------
"
installArch || errorAndExit "installing base system"
addUbuntuKeyserver || errorAndExit "adding Ubuntu Keyserver"
copyMirrorlist || errorAndExit "copying mirrorlist"
copyScript || errorAndExit "copying script"
genFstab || errorAndExit "generating fstab"

echo -ne "
-------------------------------------------------------------------------
                    GRUB BIOS Bootloader Install & Check
-------------------------------------------------------------------------
"
initBootloader || errorAndExit "initializing bootloader"

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 1-setup.sh
-------------------------------------------------------------------------
"
