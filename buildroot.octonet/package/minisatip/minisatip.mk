MINISATIP_VERSION = v2.0.79
MINISATIP_SITE = $(call github,catalinii,minisatip,$(MINISATIP_VERSION))
MINISATIP_LICENSE = GPL-2.0
MINISATIP_LICENSE_FILES = LICENSE
# libbacktrace zu den Abhängigkeiten hinzufügen
MINISATIP_DEPENDENCIES = openssl libbacktrace

MINISATIP_CONF_OPTS = -DENABLE_STACKTRACE=OFF -DCMAKE_CXX_STANDARD=23

# Linker-Flags von Compiler-Flags trennen!
# -lbacktrace gehört in die LINKER_FLAGS, damit der Compiler-Test nicht fehlschlägt.
MINISATIP_CONF_OPTS += -DCMAKE_CXX_FLAGS="$(TARGET_CXXFLAGS)"
MINISATIP_CONF_OPTS += -DCMAKE_EXE_LINKER_FLAGS="-lstdc++exp -lbacktrace"

define MINISATIP_REMOVE_STACKTRACE_CODE
        sed -i 's/.*std::stacktrace.*/\/\/ &/' $(@D)/src/utils.cpp
        sed -i 's/.*std::to_string(trace).*/\/\/ &/' $(@D)/src/utils.cpp
endef

define MINISATIP_INSTALL_HTML
        mkdir -p $(TARGET_DIR)/var/satip/www
        cp -r $(@D)/html/* $(TARGET_DIR)/var/satip/www/
endef

MINISATIP_POST_PATCH_HOOKS += MINISATIP_REMOVE_STACKTRACE_CODE
MINISATIP_POST_INSTALL_TARGET_HOOKS += MINISATIP_INSTALL_HTML

$(eval $(cmake-package))

