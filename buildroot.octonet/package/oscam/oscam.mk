################################################################################
#
# oscam
#
################################################################################

# Wir nutzen den offiziellen Git-Mirror (bzw. den Commit-SHA der gewünschten Version)
OSCAM_VERSION = 11961
OSCAM_SITE = https://git.streamboard.tv/common/oscam.git
OSCAM_SITE_METHOD = git
OSCAM_LICENSE = GPL-3.0
OSCAM_LICENSE_FILES = COPYING

# Abhängigkeiten definieren (OpenSSL wird für das Webinterface/Krypto zwingend benötigt)
OSCAM_DEPENDENCIES = openssl

# Standard-Optionen für das OSCam-CMake-Skript übergeben
OSCAM_CONF_OPTS = \
	-DCS_CONFDIR=/etc/oscam \
	-DWITH_SSL=ON \
	-DWEBIF=ON

# Optionale USB-Kartenleser-Unterstützung (z.B. für Easymouse 2 via libusb), falls im System aktiv
ifeq ($(BR2_PACKAGE_LIBUSB),y)
OSCAM_DEPENDENCIES += libusb
OSCAM_CONF_OPTS += -DWITH_LIBUSB=ON
else
OSCAM_CONF_OPTS += -DWITH_LIBUSB=OFF
endif

# Schritt 1: Konfigurationsverzeichnis auf dem Zielsystem anlegen
define OSCAM_CREATE_CONF_DIR
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/etc/oscam
endef
OSCAM_POST_INSTALL_TARGET_HOOKS += OSCAM_CREATE_CONF_DIR

# Schritt 2: SysV-Init-Autostart-Skript kopieren (wird beim Booten ausgeführt)
#define OSCAM_INSTALL_INIT_SYSV
#	$(INSTALL) -D -m 0755 $(OSCAM_PKGDIR)/S99oscam $(TARGET_DIR)/etc/init.d/S99oscam
#endef

# Der finale Aufruf für Buildroots CMake-Paket-Engine
$(eval $(cmake-package))
