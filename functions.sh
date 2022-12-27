#---------------------------------------------------------
# Locale

setLocale () {
	sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
	locale-gen
	timedatectl --no-ask-password set-timezone ${TIMEZONE}
	timedatectl --no-ask-password set-ntp 1
	localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
	ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
	
	# Set keymaps
	localectl --no-ask-password set-keymap ${KEYMAP}
	echo '
LANG=en_US.UTF-8' | tee --append /etc/locale.conf
}

getIso () {
	curl -4 ifconfig.co/country-iso
}

testIso () {
	if [ $iso = $(getIso) ];
	then
		echo "iso ok"
	else
		echo "iso not ok"
		exit
	fi
}

#---------------------------------------------------------
# Pacman

pacmanInstall () {
	if pacman -S --noconfirm --needed $@;
	then
		echo "Installation complete"
	else
		echo "Error installing $@"
		exit
	fi
}

pacmanActivateParallelDl () {
	sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
}

pacmanEnableMultilib () {
	sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
}

installOpenBuildSystem () {
	curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/x86_64/home_ungoogled_chromium_Arch.key' | pacman-key -a -
	echo '
[home_ungoogled_chromium_Arch]
SigLevel = Required TrustAll
Server = https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/$arch' | tee --append /etc/pacman.conf

	pacman -Sy --noconfirm
}

setupPacmanMirrors () {
	cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
	reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
}

setTerminusFont () {
	pacmanInstall terminus-font
	setfont ter-v22b
}

#------------------------------------------------------------------
# Filesystem

formatDisk () {
	umount -A --recursive /mnt # make sure everything is unmounted before we start# disk prep
	sgdisk -Z ${DISK} # zap all on disk
	sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment
	
	# create partitions
	sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
	sgdisk -n 2::+1G --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
	sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
	if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
		sgdisk -A 1:set:2 ${DISK}
	fi
	partprobe ${DISK} # reread partition table to ensure it is correct
}

createsubvolumes () {
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@.snapshots
}

mountallsubvol () {
    mount -o ${mountoptions},subvol=@home ${partition3} /mnt/home
    mount -o ${mountoptions},subvol=@.snapshots ${partition3} /mnt/.snapshots
    mount -o ${mountoptions},subvol=@var ${partition3} /mnt/var
}

subvolumesetup () {
    createsubvolumes
    umount /mnt
    mount -o ${mountoptions},subvol=@ ${partition3} /mnt
    mkdir -p /mnt/{home,var,.snapshots}
    mountallsubvol
}

formatBtrfs () {
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
    mkfs.btrfs -L ROOT ${partition3} -f
    mount -t btrfs ${partition3} /mnt
		subvolumesetup
}

formatLuksBtrfs () {
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
# enter luks password to cryptsetup and format root partition
    echo -n "${luks_password}" | cryptsetup -y -v luksFormat ${partition3} -
# open luks container and ROOT will be place holder 
    echo -n "${luks_password}" | cryptsetup open ${partition3} ROOT -
# now format that container
    mkfs.btrfs -L ROOT ${partition3}
# create subvolumes for btrfs
    mount -t btrfs ${partition3} /mnt
    subvolumesetup
# store uuid of encrypted partition for grub
    echo encryped_partition_uuid=$(blkid -s UUID -o value ${partition3}) >> setup.conf
}

mountBoot () {
	mkdir -p /mnt/boot/efi
	mount -t vfat -L EFIBOOT /mnt/boot/
}

setSwap () {
	if [[ $swapmb -gt 0 ]]; then
    mkdir -p /mnt/opt/swap
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=$swapmb status=progress
    chattr +C /mnt/opt/swap/swapfile #apply NOCOW, btrfs needs that.
    chmod 600 /mnt/opt/swap/swapfile #set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    echo "vm.swappiness=10" >> /mnt/etc/sysctl.conf # Lower swappiness
	fi
}

#----------------------------------------------------------
# System

installArch () {
	pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt zsh networkmanager helix pipewire pipewire-alsa gst-plugin-pipewire pipewire-media-session pipewire-pulse pipewire-v4l2 --noconfirm --needed
}

addUbuntuKeyserver () {
	echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
}

copyMirrorlist () {
	cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
}

copyScript () {
	cp -R ${SCRIPT_DIR} /mnt/root/${SCRIPTHOME}
}

genFstab () {
	genfstab -L /mnt >> /mnt/etc/fstab
}

initBootloader () {
	if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK}
	else
    pacstrab /mnt efibootmgr --noconfirm --needed
	fi
}

installEfiGrub () {
	grub-install --efi-directory=/boot ${DISK}
}

addcryptDeviceToGrub () {
	sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${encryped_partition_uuid}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
}

makeGrubCfg () {
	grub-mkconfig -o /boot/grub/grub.cfg
}

sudoNoPw () {
	sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
	sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
}

prodSudoConf () {
# Remove no password sudo rights
	sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
	sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
	sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
	sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
}

installMicroCode() {
# determine processor type and install microcode
	proc_type=$(lscpu)
	if grep -E "GenuineIntel" <<< ${proc_type}; then
    echo "Installing Intel microcode"
    pacmanInstall  intel-ucode
    proc_ucode=intel-ucode.img
	elif grep -E "AuthenticAMD" <<< ${proc_type}; then
    echo "Installing AMD microcode"
    pacmanInstall amd-ucode
    proc_ucode=amd-ucode.img
	fi
}

installGpuDriver () {
	gpu_type=$(lspci)
	if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    pacmanInstall nvidia nvidia-utils
	elif grep -E "Radeon" <<< ${gpu_type}; then
    pacmanInstall mesa lib32-mesa xf86-video-amdgpu amdvlk lib32-amdvlk radeontop libva-mesa-driver mesa-vdpau
	elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    pacmanInstall libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa intel-gpu-tools intel-media-driver
	elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    pacmanInstall libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa intel-gpu-tools intel-media-driver
	elif grep -E "Iris Xe Graphics" <<< ${gpu_type}; then
    pacmanInstall libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa intel-gpu-tools intel-media-driver
	fi
}

initUserAndMachine () {
  groupadd libvirt
  useradd -m -G wheel,libvirt,uucp,input -s /bin/bash $USERNAME 

# use chpasswd to enter $USERNAME:$PASSWORD
  echo "$USERNAME:$PASSWORD" | chpasswd
	cp -R /root/$SCRIPTHOME /home/$USERNAME/
  chown -R $USERNAME: /home/$USERNAME/$SCRIPTHOME
# enter $nameofmachine to /etc/hostname
	echo $nameofmachine > /etc/hostname
}

addEncryptToMkinit () {
	sed -i 's/filesystems/encrypt filesystems/g' /etc/mkinitcpio.conf
# making mkinitcpio with linux kernel
  mkinitcpio -p linux
}

setMakeAndCompress () {
	nc=$(grep -c ^processor /proc/cpuinfo)
	sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
	sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
}

#-----------------------------------------------------------
# Packages

installRust () {
	pacmanInstall rustup
	rustup toolchain install stable
}

installParu () {
	mkdir -p ~/build
	cd ~/build
	git clone "https://aur.archlinux.org/paru.git"
	cd ~/build/paru
	makepkg -si --noconfirm
	cd ~
}

#------------------------------------------------------------
# Misc

errorAndExit () {
	echo "Error in script: $@"
	exit
}

