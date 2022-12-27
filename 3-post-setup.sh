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

Final Setup and Configurations
GRUB EFI Bootloader Install & Check
"
source /root/$SCRIPTHOME/setup.conf
source /root/$SCRIPTHOME/functions.sh

if [[ -d "/sys/firmware/efi" ]]; then
    installEfiGrub || errorAndExit "installing efi grub"
fi

# set kernel parameter for decrypting the drive
if [[ "${FS}" == "luks" ]]; then
    addcryptDeviceToGrub || errorAndExit "adding crypt device to grub"
fi

makeGrubCfg || errorAndExit "Making Grub Config"

echo -ne "
-------------------------------------------------------------------------
                    Changing Shell for User to zsh
-------------------------------------------------------------------------
"
chsh -s /bin/zsh $USERNAME

echo -ne "
-------------------------------------------------------------------------
                    Enabling Essential Services
-------------------------------------------------------------------------
"
ntpd -qg
systemctl enable ntpd.service
systemctl disable dhcpcd.service
systemctl stop dhcpcd.service
systemctl enable NetworkManager.service
su $USERNAME -c "systemctl enable pipewire --user"
su $USERNAME -c "systemctl enable pipewire-pulse --user"
case $laptop in
    y|Y|yes|Yes|YES)
    systemctl enable --now auto-cpufreq.service;;
    *) echo "not enabling laptop services";;
esac
echo -ne "
-------------------------------------------------------------------------
                    Configure pipewire
-------------------------------------------------------------------------
"
/home/$USERNAME/$SCRIPTHOME/pipewire/create_config.sh
echo -ne "
-------------------------------------------------------------------------
                    Harden System
-------------------------------------------------------------------------
"
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo -ne "
-------------------------------------------------------------------------
                    Cleaning 
-------------------------------------------------------------------------
"
prodSudoConf

rm -r /root/$SCRIPTHOME
rm -r /home/$USERNAME/$SCRIPTHOME

# Replace in the same state
cd $pwd
