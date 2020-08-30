# Install Script
> Add it to the list of pointless thing's I've done folks!

A script to install arch, just the way i like it

> Just gonna say, macs come with the os preinstalled :^)
## How to use 
in an arch installer, set up your partition and have `/` and `/boot` mounted relative to `/mnt`

The regular way:

```sh
curl https://files.et1.uk/install.sh > install.sh
chmod +x install.sh
ADDUSER=1 install.sh hostname username
```

The add user option adds a user called username in the wheel group, and sets up the system to use my dotfiles

## Cool stuff

```bash
# CPU vendor detection
if [ $vendor = "GenuineIntel" ]; then
    arch-chroot /mnt pacman -S --noconfirm intel-ucode
    echo "initrd /intel-ucode.img" >> /mnt/boot/loader/entries/arch.conf
fi
if [ $vendor = "AuthenticAMD" ]; then
    arch-chroot /mnt pacman -S --noconfirm amd-ucode
    echo "initrd /amd-ucode.img" >> /mnt/boot/loader/entries/arch.conf
fi
```