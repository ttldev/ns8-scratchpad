#!/bin/bash

#
# Clean up data and control plane init.sh
#

shopt -s nullglob
exec </var/lib/nethserver/uninstall/files.lst

tmp_dirlist=$(mktemp)
trap "rm -f ${tmp_dirlist}" EXIT

for userhome in /home/*; do
    moduleid=$(basename $userhome)
    echo "[NOTICE] Deleting rootless module ${moduleid}..."
    loginctl disable-linger "${moduleid}"
    until ! loginctl show-user "${moduleid}" &>/dev/null; do
        sleep 1
    done

    userdel -r "${moduleid}"
done

echo "[NOTICE] Stopping the core services"
systemctl disable --now agent@\*.service redis.service

echo "[NOTICE] Uninstalling the core image files"
while read image_entry; do
    if [[ -d ${image_entry} ]]; then
        echo ${image_entry} >> $tmp_dirlist
        continue
    fi
    
    [[ -e ${image_entry} ]] && rm -vf ${image_entry}
done

echo "[NOTICE] Disable WireGuard wg0 interface"
systemctl disable --now wg-quick@wg0

echo "[NOTICE] Wipe Podman storage"
podman system reset

echo "[NOTICE] Some files may be left in the following directories:"
cat ${tmp_dirlist}

systemctl daemon-reload
