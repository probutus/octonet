################################################################################
#
# octoscan
#
################################################################################

OCTOSCAN_VERSION = 0.1
# TOPDIR zeigt absolut auf dein Buildroot-Hauptverzeichnis. 
# Damit wird der Pfad zu deinem Quellcode-Ordner eindeutig aufgelöst.
OCTOSCAN_SITE = $(TOPDIR)/../octoscan
OCTOSCAN_SITE_METHOD = local
OCTOSCAN_INSTALL_TARGET = YES

# WICHTIG: Erzeugt die korrekte Build-Reihenfolge. octoscan benötigt die 
# Header des dddvb-Treibers, um kompiliert werden zu können.
OCTOSCAN_DEPENDENCIES = linux dddvb

define OCTOSCAN_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) \
		CFLAGS="$(TARGET_CFLAGS) -I$(DDDVB_DIR)/include -I$(DDDVB_DIR)/ddbridge"
endef

define OCTOSCAN_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/octoscan $(TARGET_DIR)/usr/bin/octoscan
endef

$(eval $(generic-package))

