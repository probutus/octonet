#!/bin/sh
# Prüft, ob das aktuelle Interface ($IFACE) für das NFS-Rootfs genutzt wird

# Extrahiert die IP des NFS-Servers aus den Kernel-Mount-Infos
nfsip=$(sed -n '/^[^ ]*:.* \/ nfs.*[ ,]addr=\([0-9.]\+\).*/s//\1/p' /proc/mounts)

# Falls ein NFS-Root aktiv ist, prüfen wir, ob die Route dorthin über dieses Interface läuft
if [ -n "$nfsip" ] && ip route get to "$nfsip" | grep -q "dev $IFACE"; then
    echo "skipping $IFACE: is nfsroot"
    exit 1 # Ein Exit-Code ungleich 0 bricht das ifup für dieses Interface ab
fi

