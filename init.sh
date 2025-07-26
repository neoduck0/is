#!/usr/bin/env bash

# gpt|mbr
if [ -d "/sys/firmware/efi" ]; then
    disk_label="gpt"
else
    disk_label="mbr"
fi

# Leave empty to disable
disk_pass=

server=false
omz=true
yay=true
timezone=$(curl -s https://ipinfo.io/timezone)
if [ ! -f "/usr/share/zoneinfo/$timezone" ]; then
    timezone="UTC"
fi
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

for var in server omz yay; do
    if [[ -z "${!var}" || ! "${!var}" =~ ^(true|false)$ ]]; then
        echo "Variable $var is unset or set uncorrectly"
        exit 1
    fi
done

for var in timezone user user_pass root_pass disk; do
    if [[ -z "${!var}" ]]; then
        echo "Variable $var is unset or set uncorrectly"
        exit 1
    fi
done
