################################################################################
#
# dddvb
#
################################################################################

DDDVB_VERSION = 0.9.41
DDDVB_SITE = $(call github,DigitalDevices,dddvb,$(DDDVB_VERSION))
DDDVB_SOURCE = dddvb-$(DDDVB_VERSION).tar.gz

# ==============================================================================
# TEIL 1: KERNEL-MODULE (Infrastruktur: kernel-module)
# ==============================================================================
DDDVB_MODULE_SUBDIRS = .

# Wir nutzen NOSTDINC_FLAGS exakt so, wie es das originale dddvb-Makefile verlangt,
# übergeben aber die absoluten Buildroot-Pfade via $(@D).
# Dadurch werden die lokalen Tuner-Header (wie tda18271c2dd.h) und die dd_compat.h
# (löst das KERNEL_VERSION-Problem) fehlerfrei geladen.
DDDVB_MODULE_MAKE_OPTS = \
	CONFIG_DVB_CORE=m \
	CONFIG_DVB_DDBRIDGE=m \
	CONFIG_DVB_DRXK=m \
	CONFIG_DVB_TDA18271C2DD=m \
	CONFIG_DVB_CXD2099=m \
	CONFIG_DVB_LNBP21=m \
	CONFIG_DVB_STV090x=m \
	CONFIG_DVB_STV6110x=m \
	CONFIG_DVB_STV0367=m \
	CONFIG_DVB_TDA18212=m \
	CONFIG_DVB_STV0367DD=m \
	CONFIG_DVB_TDA18212DD=m \
	CONFIG_DVB_OCTONET=m \
	CONFIG_DVB_CXD2843=m \
	CONFIG_DVB_STV0910=m \
	CONFIG_DVB_STV6111=m \
	CONFIG_DVB_LNBH25=m \
	CONFIG_DVB_MXL5XX=m \
	DDDVB=y \
	CONFIG_DVB_NET=y \
	NOSTDINC_FLAGS="--include=$(@D)/include/dd_compat.h -I$(@D)/frontends -I$(@D)/include -I$(@D)/include/linux -I$(@D)/include/linux/media -I$(@D)/dvb-core"

# ==============================================================================
# TEIL 2: USER-SPACE KOMPONENTE (Infrastruktur: generic-package)
# ==============================================================================
DDDVB_DEPENDENCIES = linux

define DDDVB_BUILD_CMDS
	# 1. Standard-Apps aus dem apps/ Ordner bauen
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/apps $(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS) -fms-extensions -Dddoctonet -I$(@D)/include -I$(@D)/ddbridge"
	
	# 2. Octonet-spezifische Apps bauen (falls vorhanden)
	if [ -d $(@D)/apps/octonet ]; then \
		$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/apps/octonet $(TARGET_CONFIGURE_OPTS) \
			CFLAGS="$(TARGET_CFLAGS) -fms-extensions -Dddoctonet -I$(@D)/include -I$(@D)/ddbridge"; \
	fi
endef

define DDDVB_INSTALL_TARGET_CMDS
	# Installiert alle Binärdateien nach /usr/bin/ im Target-Dateisystem
	$(INSTALL) -m 0755 -D $(@D)/apps/octonet/ddtest $(TARGET_DIR)/usr/bin/ddtest
	$(INSTALL) -m 0755 -D $(@D)/apps/ddinfo $(TARGET_DIR)/usr/bin/ddinfo
	$(INSTALL) -m 0755 -D $(@D)/apps/octonet/octonet $(TARGET_DIR)/usr/bin/octonet
	$(INSTALL) -m 0755 -D $(@D)/apps/octonet/octokey $(TARGET_DIR)/usr/bin/octokey
	$(INSTALL) -m 0755 -D $(@D)/apps/ddlicense $(TARGET_DIR)/usr/bin/ddlicense
	$(INSTALL) -m 0755 -D $(@D)/apps/modconfig $(TARGET_DIR)/usr/bin/modconfig
	$(INSTALL) -m 0755 -D $(@D)/apps/cit $(TARGET_DIR)/usr/bin/cit
	$(INSTALL) -m 0755 -D $(@D)/apps/getiq $(TARGET_DIR)/usr/bin/getiq
	$(INSTALL) -m 0755 -D $(@D)/apps/octonet/ddflash $(TARGET_DIR)/usr/bin/ddflash
	$(INSTALL) -m 0755 -D $(@D)/apps/octonet/ddupdate $(TARGET_DIR)/usr/bin/ddupdate
	$(INSTALL) -m 0755 -D $(@D)/apps/modtest $(TARGET_DIR)/usr/bin/modtest
	$(INSTALL) -m 0755 -D $(@D)/apps/setmod1 $(TARGET_DIR)/usr/bin/setmod1
	$(INSTALL) -m 0755 -D $(@D)/apps/setmod2 $(TARGET_DIR)/usr/bin/setmod2
endef

# ==============================================================================
# TEIL 3: HOOKS & INFRASTRUKTUR-EVALUIERUNG
# ==============================================================================

# Der Hook löscht die Stempeldateien dieses Pakets, sobald "make linux-rebuild" 
# oder eine automatische Änderung am Kernel triggert.
define DDDVB_TRIGGER_REBUILD
	rm -f $(@D)/.stamp_built
	rm -f $(@D)/.stamp_target_installed
endef
LINUX_POST_INSTALL_TARGET_HOOKS += DDDVB_TRIGGER_REBUILD

# Wichtig: Zuerst das Kernel-Modul evaluieren, danach das generische Paket!
$(eval $(kernel-module))
$(eval $(generic-package))

