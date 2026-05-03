TARGETDIR=$1

grep -q config $TARGETDIR/etc/fstab || echo -e "/dev/ubi0_0\t\t/config\tubifs\tdefaults\t0\t0" >> $TARGETDIR/etc/fstab
grep -q pts $TARGETDIR/etc/securetty || echo -e "pts/0\npts/1\npts/2\npts/3" >> $TARGETDIR/etc/securetty

mkdir -p $TARGETDIR/config

grep -q console $TARGETDIR/etc/securetty || echo -e "console" >> $TARGETDIR/etc/securetty

chmod 777 $TARGETDIR/var/monitor/fancontrol.lua  


