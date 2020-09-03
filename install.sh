#!/bin/sh
RED='\033[0;31m'
NC='\033[0m' # No Color
bold=$(tput bold)
normal=$(tput sgr0)
title() {
    echo -e "${bold}==> ${RED}$1${NC}"
}

title "Downloading mirrorlist"
curl "https://www.archlinux.org/mirrorlist/?country=GB&protocol=https" |\
tac | tac | sed 's/#Server/Server/' > /etc/pacman.d/mirrorlist 

title "Running pacstrap"
pacstrap /mnt base linux linux-firmware networkmanager

title "Generating Files"
genfstab -U /mnt >> /mnt/etc/fstab
mv /mnt/etc/locale.gen /mnt/etc/locale.gen_old
echo "en_GB.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "KEYMAP=uk" > /etc/vconsole.conf
echo "LANG=en_GB.UTF-8" > /mnt/etc/locale.conf
echo $1 > /mnt/etc/hostname

timedatectl set-ntp true

title Running Commands Within chroot
arch-chroot /mnt locale-gen
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt hwclock --systohc

title "Generating Bootloader Entry"
arch-chroot /mnt bootctl install
echo "title Arch Linux" >> /mnt/boot/loader/entries/arch.conf
echo "linux /vmlinuz-linux" >> /mnt/boot/loader/entries/arch.conf

vendor=$(cat /proc/cpuinfo | grep 'vendor' | uniq | cut -d ' ' --fields=2)

if [ $vendor = "GenuineIntel" ]; then
    arch-chroot /mnt pacman -S --noconfirm intel-ucode
    echo "initrd /intel-ucode.img" >> /mnt/boot/loader/entries/arch.conf
fi
if [ $vendor = "AuthenticAMD" ]; then
    arch-chroot /mnt pacman -S --noconfirm amd-ucode
    echo "initrd /amd-ucode.img" >> /mnt/boot/loader/entries/arch.conf
fi

echo "initrd /initramfs-linux.img" >> /mnt/boot/loader/entries/arch.conf
if [ $ADDUSER -ne 0 ]; then
echo "options root=UUID=\"$(lsblk -no UUID $(mount | grep "on /mnt " | cut -d ' ' --fields=1))\" rw quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0" >> /mnt/boot/loader/entries/arch.conf
else
echo "options root=UUID=\"$(lsblk -no UUID $(mount | grep "on /mnt " | cut -d ' ' --fields=1))\" rw" >> /mnt/boot/loader/entries/arch.conf
fi
arch-chroot /mnt bootctl update

if [ $ADDUSER -ne 0 ]; then
user=$2

arch-chroot /mnt useradd -m -G wheel $user

arch-chroot /mnt pacman -S --noconfirm git sudo base-devel go

cp /mnt/etc/sudoers /mnt/etc/sudoers.old
echo "root ALL=(ALL) ALL" >> /mnt/etc/sudoers
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /mnt/etc/sudoers

arch-chroot /mnt sudo -u $user bash -c "cd; git clone https://aur.archlinux.org/yay.git; cd yay; makepkg"
arch-chroot /mnt pacman --noconfirm -U $(find /mnt/home/$user/yay | grep \\.pkg | sed 's/\/mnt//g')

arch-chroot /mnt sudo -u $user yay -S --noconfirm --removemake --nodiffmenu --noeditmenu plymouth plymouth-theme-arch-charge

sed -i /mnt/etc/mkinitcpio.conf -e 's/^HOOKS=(base udev/HOOKS=(base udev plymouth/g'
arch-chroot /mnt mkinitcpio -p linux

echo "[Daemon]" > /mnt/etc/plymouth/plymouthd.conf
echo "Theme=arch-charge" >> /mnt/etc/plymouth/plymouthd.conf
echo "ShowDelay=5" >> /mnt/etc/plymouth/plymouthd.conf
echo "DeviceTimeout=8" >> /mnt/etc/plymouth/plymouthd.conf


arch-chroot /mnt pacman --noconfirm -S lightdm lightdm-webkit2-greeter lightdm-webkit-theme-litarvan
arch-chroot /mnt systemctl enable lightdm-plymouth

sed -i /mnt/etc/lightdm/lightdm.conf -e 's/^#greeter-session=example-gtk-gnome/greeter-session=lightdm-webkit2-greeter/'
sed -i /mnt/etc/lightdm/lightdm-webkit2-greeter.conf -e 's/antergos/litarvan/g'

rm -rf //mnt/home/$user/{*,.*}
arch-chroot /mnt sudo -u $user bash -c "cd; git clone https://github.com/Emersont1/dotfiles .; ./configs_install.sh"

rm /mnt/etc/sudoers 
mv /mnt/etc/sudoers.old /mnt/etc/sudoers

echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers

title "Setting $user password - use this to login"
arch-chroot /mnt passwd $user

fi

title "Setting root password - Don't lose this!"
arch-chroot /mnt passwd