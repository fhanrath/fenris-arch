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

echo -ne "
-------------------------------------------------------------------------
                    Manual Installs
-------------------------------------------------------------------------
"
mkdir ~/build
cd ~/build
git clone "https://aur.archlinux.org/paru.git"
cd ~/build/paru
rustup toolchain install stable
makepkg -si --noconfirm

cd ~/build
git clone https://github.com/fhanrath/sway-save-outputs
cd ~/build/sway-save-outputs
sudo ./install.sh
cd ~/build

echo -ne "
-------------------------------------------------------------------------
                    Install Portmaster
-------------------------------------------------------------------------
"
# Clone the repository
git clone https://github.com/safing/portmaster-packaging

# Enter the repo and build/install the package (it's under linux/)
cd portmaster-packaging/linux
makepkg -si --noconfirm

cd ~


echo -ne "
-------------------------------------------------------------------------
                    Install AUR Packages
-------------------------------------------------------------------------
"

paru -S --noconfirm --needed - < ~/$SCRIPTHOME/pkg-files/aur-pkgs.txt

paru -S --noconfirm --needed - < ~/$SCRIPTHOME/pkg-files/aur-pkgs-sway.txt

case $games in
    y|Y|yes|Yes|YES)
    paru -S --noconfirm --needed - < ~/$SCRIPTHOME/pkg-files/aur-pkgs-gaming.txt;;
    *) echo "not installing gaming packages";;
esac

case $laptop in
    y|Y|yes|Yes|YES)
    paru -S --noconfirm --needed - < ~/$SCRIPTHOME/pkg-files/aur-pkgs-laptop.txt;;
    *) echo "not installing laptop packages";;
esac

touch "~/.cache/zshhistory"
cd ~
git clone "https://git.sr.ht/~fenris/dotfiles"
cd dotfiles
./copy_dotfiles.sh
sudo ./copy_root_dotfiles.sh
cd ~

export PATH=$PATH:~/.local/bin

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 3-post-setup.sh
-------------------------------------------------------------------------
"
exit
