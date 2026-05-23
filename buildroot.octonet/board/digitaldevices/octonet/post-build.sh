#!/bin/bash
# post-build.sh für Buildroot 2025.02
set -e

TARGETDIR=$1

grep -q config $TARGETDIR/etc/fstab || echo -e "/dev/ubi0_0\t\t/config\tubifs\tdefaults\t0\t0" >> $TARGETDIR/etc/fstab
grep -q pts $TARGETDIR/etc/securetty || echo -e "pts/0\npts/1\npts/2\npts/3" >> $TARGETDIR/etc/securetty
grep -q console $TARGETDIR/etc/securetty || echo -e "console" >> $TARGETDIR/etc/securetty

if [ -e "$TARGETDIR/var/monitor/fancontrol.lua" ]; then
    chmod 755 "$TARGETDIR/var/monitor/fancontrol.lua"
fi

# HINWEIS: Fehlende schließende Anführungszeichen (") wurden korrigiert!
if [ -e "$TARGETDIR/boot/zImage" ] && [ -e "$TARGETDIR/boot/at91-octonet.dtb" ]; then
   
   # Zusammenführen direkt in den RAM (/tmp/), um Flash/SSD-Schreibzyklen zu sparen
   cat "$TARGETDIR/boot/zImage" "$TARGETDIR/boot/at91-octonet.dtb" > /tmp/zImage.appended
   
   "$HOST_DIR/bin/mkimage" -A arm -O linux -T kernel -C none \
      -a 0x72000000 -e 0x72000000 \
      -n "Linux-Appended" \
      -d /tmp/zImage.appended \
      "$TARGETDIR/boot/uImage"
   
   rm /tmp/zImage.appended
fi

mkdir -p "$TARGETDIR/config"

