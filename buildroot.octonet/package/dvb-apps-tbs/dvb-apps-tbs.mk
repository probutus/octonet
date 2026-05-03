DVB_APPS_TBS_VERSION = master
DVB_APPS_TBS_SITE = $(call github,tbsdtv,dvb-apps,$(DVB_APPS_TBS_VERSION))
DVB_APPS_TBS_LICENSE = GPL-2.0, LGPL-2.1
DVB_APPS_TBS_INSTALL_STAGING = YES

# Wichtig: Die CFLAGS müssen auch die Pfade innerhalb des Quellcodes kennen
DVB_APPS_TBS_MAKE_OPTS = $(TARGET_CONFIGURE_OPTS) CFLAGS="$(TARGET_CFLAGS) -I$(@D)/lib -DLOG_LEVEL=3 -DERROR=1"

define DVB_APPS_TBS_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/lib $(DVB_APPS_TBS_MAKE_OPTS)
endef

define DVB_APPS_TBS_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/lib $(DVB_APPS_TBS_MAKE_OPTS) DESTDIR=$(STAGING_DIR) install
endef

define DVB_APPS_TBS_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/lib $(DVB_APPS_TBS_MAKE_OPTS) DESTDIR=$(TARGET_DIR) install
endef

# DIESE ZEILE HAT GEFEHLT - sie registriert das Paket in Buildroot
$(eval $(generic-package))

