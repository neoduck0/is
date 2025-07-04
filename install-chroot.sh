#!/usr/bin/env bash

set -e

cd $(dirname $0)

source init.sh

ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime
hwclock --systohc

sed -i 's|#en_US.UTF-8|en_US.UTF-8|' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo 'arch' > /etc/hostname

if [ $disk_pass ]; then
    uuid=$(blkid -s UUID -o value /dev/$root_part)
    insert_line="cryptdevice=UUID=$uuid:root root=/dev/mapper/root"
    sed -i 's|block filesystems|block encrypt filesystems|' /etc/mkinitcpio.conf
    mkinitcpio -p linux
    sed -i "s|quiet|quiet $insert_line|" /etc/default/grub
fi

echo "root:$root_pass" | chpasswd

if [ $disk_label = gpt ]; then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
    grub-install --target=i386-pc /dev/$disk
fi

grub-mkconfig -o /boot/grub/grub.cfg

pacman -Syu

useradd -mG wheel $user
echo "$user:$user_pass" | chpasswd

sed -i 's|# %wheel ALL=(ALL:ALL) ALL|%wheel ALL=(ALL:ALL) ALL|' /etc/sudoers
sed -i 's|# deny = 3|deny = 5|' /etc/security/faillock.conf

if [ $server = true ]; then
    pacman -S --needed --noconfirm $(tr '\n' ' ' < resources/pkgs-server)
    systemctl enable ufw
elif [ $server = false ]; then
    pacman -S --needed --noconfirm $(tr '\n' ' ' < resources/pkgs)
    systemctl enable bluetooth
    systemctl enable firewalld
    systemctl enable libvirtd.socket

    cp ./resources/keyd.conf /etc/keyd/default.conf
    systemctl enable keyd
    keyd reload
fi
systemctl enable NetworkManager

if [ $bat_cap = true ]; then
    echo 1 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
fi

if [ $dotfiles = true ]; then
    mkdir /home/$user/Projects
    git clone https://github.com/neoduck0/dotfiles.git /home/$user/Projects/dotfiles
    chown -R $user:$user /home/$user/Projects
    su --session-command="/home/$user/Projects/dotfiles/install.sh" $user
fi

if [ $omz = true ]; then
    su --session-command='sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"' $user
fi

if [ $yay = true ]; then
    git clone https://aur.archlinux.org/yay.git /home/$user/yay
    chown -R $user:$user /home/$user/yay
    cd /home/$user/yay
    su --session-command="makepkg -si" $user
    cd
    rm -rf /home/$user/yay
fi

echo
echo "chroot script finished"
exit 0
