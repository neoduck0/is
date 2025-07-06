#!/usr/bin/env bash

# gpt|mbr
disk_label=gpt

# ufw|firewalld
firewall=ufw

# Leave empty to disable
dotfiles_repo=https://github.com/neoduck0/dotfiles.git
disk_pass=

server=false
ideapad_bat_cap=false
omz=true
yay=true
region=Asia
city=Bangkok
user=a
user_pass=
root_pass=
disk=nvme0n1


if [ $disk_label = gpt ]; then
    if [ $disk = nvme0n1 ]; then
        efi_part=$disk'p1'
        root_part=$disk'p2'
    else
        efi_part=$disk'1'
        root_part=$disk'2'
    fi
elif [ $disk_label = mbr ]; then
    if [ $disk = nvme0n1 ]; then
        root_part=$disk'p1'
    else
        root_part=$disk'1'
    fi
fi

if [[ -z "$disk_label" || ! "$disk_label" =~ ^(gpt|mbr)$ ]]; then
    echo "Variable disk_label is unset or set uncorrectly"
    exit 1
fi

if [[ -z "$firewall" || ! "$firewall" =~ ^(ufw|firewalld)$ ]]; then
    echo "Variable firewall is unset or set uncorrectly"
    exit 1
fi

for var in server ideapad_bat_cap omz yay; do
    if [[ -z "${!var}" || ! "${!var}" =~ ^(true|false)$ ]]; then
        echo "Variable $var is unset or set uncorrectly"
        exit 1
    fi
done

for var in region city user user_pass root_pass disk; do
    if [[ -z "${!var}" ]]; then
        echo "Variable $var is unset or set uncorrectly"
        exit 1
    fi
done
