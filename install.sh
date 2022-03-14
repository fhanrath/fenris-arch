#!/bin/bash

# Find the name of the folder the scripts are in
export SCRIPTHOME="$(basename -- $PWD)"
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
-------------------------------------------------------------------------
                Scripts are in directory named $SCRIPTHOME
"
    bash startup.sh
    source setup.conf
    bash 0-preinstall.sh
    SCRIPTHOME=$SCRIPTHOME arch-chroot /mnt /root/$SCRIPTHOME/1-setup.sh
    SCRIPTHOME=$SCRIPTHOME arch-chroot /mnt /usr/bin/runuser -u $USERNAME -- /home/$USERNAME/$SCRIPTHOME/2-user.sh
    SCRIPTHOME=$SCRIPTHOME arch-chroot /mnt /root/$SCRIPTHOME/3-post-setup.sh

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
-------------------------------------------------------------------------
                Done - Please Eject Install Media and Reboot
"