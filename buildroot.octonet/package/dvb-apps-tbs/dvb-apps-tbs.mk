DVB_APPS_TBS_VERSION = master
DVB_APPS_TBS_SITE = $(call github,tbsdtv,dvb-apps,$(DVB_APPS_TBS_VERSION))
DVB_APPS_TBS_LICENSE = GPL-2.0, LGPL-2.1
DVB_APPS_TBS_INSTALL_STAGING = YES

# Wichtig: Die CFLAGS müssen auch die Pfade innerhalb des Quellcodes kennen
DVB_APPS_TBS_MAKE_OPTS = $(TARGET_CONFIGURE_OPTS) CFLAGS="$(TARGET_CFLAGS) -I$(@D)/lib -DLOG_LEVEL=3 -DERROR=1"

DVB_APPS_TBS_INTERNAL_LIBS = \
    -L$(@D)/lib/libdvbapi \
    -L$(@D)/lib/libucsi \
    -L$(@D)/lib/libdvbcfg \
    -L$(@D)/lib/libdvben50221 \
    -L$(@D)/lib/libdvbsec \
    -L$(@D)/lib/libesg

DVB_APPS_TBS_EXTRA_OPTS = \
    CFLAGS="$(TARGET_CFLAGS) -I$(@D)/lib" \
    LDFLAGS="$(TARGET_LDFLAGS) -L$(@D)/lib/libdvbapi -L$(@D)/lib/libucsi -L$(@D)/lib/libdvbcfg -L$(@D)/lib/libdvben50221 -L$(@D)/lib/libdvbsec -L$(@D)/lib/libesg"

define DVB_APPS_TBS_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE1) -C $(@D) \
		CC="$(TARGET_CC)" \
		LD="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -I$(@D)/lib" \
		LDFLAGS="$(TARGET_LDFLAGS) -L$(@D)/lib/libdvbapi -L$(@D)/lib/libucsi -L$(@D)/lib/libdvbcfg -L$(@D)/lib/libdvben50221 -L$(@D)/lib/libdvbsec -L$(@D)/lib/libesg"
endef

define DVB_APPS_TBS_INSTALL_STAGING_CMDS
	# Installiert Libs und Header für andere Pakete
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) $(DVB_APPS_TBS_MAKE_OPTS) DESTDIR=$(STAGING_DIR) install
endef

define DVB_APPS_TBS_INSTALL_TARGET_CMDS
	# Installiert Libs UND alle Binaries (zap, scan, dvbnet, etc.) ins Target
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) $(DVB_APPS_TBS_MAKE_OPTS) DESTDIR=$(TARGET_DIR) install
endef

# DIESE ZEILE HAT GEFEHLT - sie registriert das Paket in Buildroot
$(eval $(generic-package))

