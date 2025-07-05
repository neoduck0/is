#!/usr/bin/env bash

# gpt or mbr
disk_label=

# ufw or firewalld
firewall=

# true or false
server=
bat_cap=
dotfiles=
omz=
yay=

region=
city=

user=
user_pass=
root_pass=

# eg. sda, vda, nvme0n1
disk=

# Leave empty for no disk encryption
disk_pass=

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

for var in server bat_cap dotfiles omz yay; do
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
