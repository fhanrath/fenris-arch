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
                        SCRIPTHOME: $SCRIPTHOME
-------------------------------------------------------------------------

Installing AUR Softwares
"
# You can solve users running this script as root with this and then doing the same for the next for statement. However I will leave this up to you.
source ~/$SCRIPTHOME/setup.conf
source ~/$SCRIPTHOME/functions.sh

echo -ne "
-------------------------------------------------------------------------
                    Manual Installs
-------------------------------------------------------------------------
"
installRust || errorAndExit "installing rust"
installParu || errorAndExit "installing paru"

export PATH=$PATH:~/.local/bin


case $laptop in
    y|Y|yes|Yes|YES)
    paru -S --noconfirm --needed auto-cpufreq
    *) echo "not installing laptop packages";;
esac

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 3-post-setup.sh
-------------------------------------------------------------------------
"
exit
