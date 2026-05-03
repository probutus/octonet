OCTOSERVE_VERSION = 0.1
OCTOSERVE_SOURCE = 
OCTOSERVE_SITE = ../octoserve
OCTOSERVE_SITE_METHOD = local
OCTOSERVE_INSTALL_TARGET = YES
OCTOSERVE_DEPENDENCIES = linux dvb-apps-tbs

define OCTOSERVE_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
        $(TARGET_CONFIGURE_OPTS) \
        CFLAGS="$(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include" \
        LDFLAGS="$(TARGET_LDFLAGS) -L$(STAGING_DIR)/usr/lib"
endef

define OCTOSERVE_INSTALL_TARGET_CMDS
        $(INSTALL) -m 0755 -D $(@D)/octoserve $(TARGET_DIR)/usr/bin/octoserve
	cp -rd $(@D)/var $(TARGET_DIR)/
        $(INSTALL) -m 0755 -d $(TARGET_DIR)/boot
        $(INSTALL) -m 0755 $(@D)/boot/* $(TARGET_DIR)/boot/
endef

$(eval $(generic-package))
