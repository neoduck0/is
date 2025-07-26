#!/usr/bin/env bash

set -e

cd $(dirname $0)

source init.sh

ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

sed -i 's|#en_US.UTF-8|en_US.UTF-8|' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo 'arch' > /etc/hostname

if [ $disk_pass ]; then
    uuid=$(blkid -s UUID -o value /dev/$root_part)
    insert_line="cryptdevice=UUID=$uuid:root root=/dev/mapper/root"
    sed -i 's|block filesystems|block encrypt filesystems|' /etc/mkinitcpio.conf
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
elif [ $server = false ]; then
    pacman -S --needed --noconfirm $(tr '\n' ' ' < resources/pkgs)
    systemctl enable bluetooth
    systemctl enable libvirtd.socket

    cp ./resources/keyd.conf /etc/keyd/default.conf
    systemctl enable keyd
    keyd reload
fi

if pacman -Q firewalld &> /dev/null; then
    systemctl enable firewalld
fi

if pacman -Q ufw &> /dev/null; then
    systemctl enable ufw
    ufw limit 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw default deny incoming
    ufw default allow outgoing
    ufw enable
fi

systemctl enable NetworkManager

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

cd
rm -rf /root/install-scripts

echo
echo "chroot script finished"
exit 0
