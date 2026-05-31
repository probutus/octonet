################################################################################
#
# octoserve
#
################################################################################

OCTOSERVE_VERSION = 0.1
OCTOSERVE_SITE = $(TOPDIR)/../octoserve
OCTOSERVE_SITE_METHOD = local
OCTOSERVE_INSTALL_TARGET = YES

# WICHTIG: dddvb muss als Abhängigkeit definiert sein, damit dessen 
# Header-Dateien vor dem Bau von octoserve bereitstehen.
OCTOSERVE_DEPENDENCIES = linux dddvb

define OCTOSERVE_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS) -fms-extensions -I$(STAGING_DIR)/usr/include -I$(DDDVB_DIR)/include -I$(DDDVB_DIR)/ddbridge" \
		LDFLAGS="$(TARGET_LDFLAGS) -L$(STAGING_DIR)/usr/lib"
endef

define OCTOSERVE_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/octoserve $(TARGET_DIR)/usr/bin/octoserve
	
	# Verwende -a oder --parents, um Dateirechte beim Kopieren von /var exakt zu erhalten
	cp -rd $(@D)/var $(TARGET_DIR)/
	
	# Boot-Dateien sauber installieren
	$(INSTALL) -m 0755 -d $(**TARGET_DIR**)/boot
	if [ -d $(@D)/boot ] && [ "$(ls -A $(@D)/boot)" ]; then \
		cp -rd $(@D)/boot/* $(TARGET_DIR)/boot/; \
	fi
endef

$(eval $(generic-package))

