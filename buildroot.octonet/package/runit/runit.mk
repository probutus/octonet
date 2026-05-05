RUNIT_VERSION = 2.1.2
RUNIT_SOURCE = runit-$(RUNIT_VERSION).tar.gz
RUNIT_SITE = http://smarden.org/runit
RUNIT_LICENSE = BSD-3-Clause
RUNIT_LICENSE_FILES = package/COPYING

define RUNIT_BUILD_CMDS
	cd $(@D)/runit-2.1.2/src && \
	echo "$(TARGET_CC) $(TARGET_CFLAGS) -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration -D_GNU_SOURCE -Dsigblock\(m\)=0 -Dsigsetmask\(m\)=0" > conf-cc && \
	echo "$(TARGET_CC) $(TARGET_LDFLAGS)" > conf-ld && \
	sed -i 's/.\/choose/true/g' Makefile && \
	sed -i 's/.\/chkshsgr/true/g' Makefile && \
	sed -i 's/sh find-systype.sh > systype/echo linux > systype/g' Makefile && \
	sed -i 's/grep sysdep.*/true/g' Makefile && \
	echo "/* sysdep */" > uint64.h && \
	echo "typedef unsigned long long uint64;" >> uint64.h && \
	echo "#ifndef TAI_H" > tai.h && \
	echo "#define TAI_H" >> tai.h && \
	echo "#include \"uint64.h\"" >> tai.h && \
	echo "struct tai { uint64 x; };" >> tai.h && \
	echo "#define TAI_PACK 8" >> tai.h && \
	echo "#define tai_unix(t,u) ((void) ((t)->x = 4611686018427387914ULL + (uint64) (u)))" >> tai.h && \
	echo "void tai_pack(); void tai_unpack();" >> tai.h && \
	echo "#endif" >> tai.h && \
	echo "#ifndef TAIA_H" > taia.h && \
	echo "#define TAIA_H" >> taia.h && \
	echo "#include \"tai.h\"" >> taia.h && \
	echo "struct taia { struct tai sec; unsigned long nano; unsigned long atto; };" >> taia.h && \
	echo "#define TAIA_PACK 16" >> taia.h && \
	echo "void taia_now(); void taia_pack(); void taia_unpack(); void taia_add(); void taia_sub(); void taia_uint(); int taia_less(); double taia_approx();" >> taia.h && \
	echo "#endif" >> taia.h && \
	echo "#ifndef IOPAUSE_H" > iopause.h && \
	echo "#define IOPAUSE_H" >> iopause.h && \
	echo "#include <sys/poll.h>" >> iopause.h && \
	echo "#include <sys/time.h>" >> iopause.h && \
	echo "#include \"taia.h\"" >> iopause.h && \
	echo "typedef struct pollfd iopause_fd;" >> iopause.h && \
	echo "#define IOPAUSE_POLL" >> iopause.h && \
	echo "#define IOPAUSE_READ POLLIN" >> iopause.h && \
	echo "#define IOPAUSE_WRITE POLLOUT" >> iopause.h && \
	echo "void iopause();" >> iopause.h && \
	echo "#endif" >> iopause.h && \
	echo "/* sysdep */" > direntry.h && \
	echo "#include <dirent.h>" >> direntry.h && \
	echo "typedef struct dirent direntry;" >> direntry.h && \
	echo "#define HASSHORTGROUPS 0" > hasshsgr.h && \
	echo "#define HASSELECT 1" > select.h && \
	echo "int main(){return 0;}" > chkshsgr.c && \
	echo "void reboot_system(){}" > reboot_system.c && \
	echo "double taia_approx(void* t){return 0;}" > taia_approx.c && \
	echo "int main(){return 0;}" > runit.c && \
	echo "linux" > systype && \
	touch *.h chkshsgr.c reboot_system.c runit.c taia_approx.c systype && \
	$(MAKE) -C $(@D)/runit-2.1.2/src
endef

define RUNIT_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/runit-2.1.2/src/runsv $(TARGET_DIR)/usr/bin/runsv
	$(INSTALL) -m 0755 -D $(@D)/runit-2.1.2/src/runsvdir $(TARGET_DIR)/usr/bin/runsvdir
	$(INSTALL) -m 0755 -D $(@D)/runit-2.1.2/src/sv $(TARGET_DIR)/usr/bin/sv
	$(INSTALL) -m 0755 -D $(@D)/runit-2.1.2/src/svlogd $(TARGET_DIR)/usr/bin/svlogd
	$(INSTALL) -m 0755 -D $(@D)/runit-2.1.2/src/chpst $(TARGET_DIR)/usr/bin/chpst
	$(INSTALL) -m 0755 -D $(@D)/runit-2.1.2/src/runit-init $(TARGET_DIR)/usr/bin/runit-init
endef

$(eval $(generic-package))

