#!/usr/bin/env bash

set -e

cd $(dirname $0)

source init.sh

if [ $disk_label = gpt ]; then
    sgdisk --zap-all /dev/$disk
    sgdisk --new=1:0:+1G /dev/$disk
    sgdisk --new=2:0:0 /dev/$disk
elif [ $disk_label = mbr ]; then
    wipefs -a /dev/$disk
    parted /dev/sda mklabel msdos --script
    parted /dev/sda mkpart primary ext4 0% 100% --script
fi

echo -n "$disk_pass" | cryptsetup luksFormat --batch-mode /dev/$root_part
echo -n "$disk_pass" | cryptsetup luksOpen --batch-mode /dev/$root_part root
mkfs.ext4 /dev/mapper/root -F
mount /dev/mapper/root /mnt

pacman -Syy

if [ $disk_label = gpt ]; then
    mkfs.fat -F32 /dev/$efi_part
    mount --mkdir /dev/$efi_part /mnt/boot
    pacstrap -K /mnt base base-devel efibootmgr git grub linux linux-firmware neovim
elif [ $disk_label = mbr ]; then
    pacstrap -K /mnt base base-devel git grub linux linux-firmware neovim
fi

genfstab -U /mnt > /mnt/etc/fstab

cp -r ../install-scripts /mnt/root/install-scripts

echo "root:$root_pass" | chpasswd --root /mnt
useradd -mG wheel $user --root /mnt
echo "$user:$user_pass" | chpasswd --root /mnt

arch-chroot /mnt "/root/install-scripts/install-chroot.sh"

echo
echo "installation complete"
exit 0
