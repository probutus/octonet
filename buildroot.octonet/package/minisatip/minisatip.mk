MINISATIP_VERSION = v2.0.79
MINISATIP_SITE = $(call github,catalinii,minisatip,$(MINISATIP_VERSION))
MINISATIP_LICENSE = GPL-2.0
MINISATIP_LICENSE_FILES = LICENSE
MINISATIP_DEPENDENCIES = openssl
MINISATIP_CONF_OPTS = -DENABLE_STACKTRACE=OFF -DCMAKE_CXX_STANDARD=23

MINISATIP_CONF_OPTS += -DCMAKE_CXX_FLAGS="$(TARGET_CXXFLAGS) -lstdc++exp -lbacktrace"

define MINISATIP_REMOVE_STACKTRACE_CODE
	sed -i 's/.*std::stacktrace.*/\/\/ &/' $(@D)/src/utils.cpp
	sed -i 's/.*std::to_string(trace).*/\/\/ &/' $(@D)/src/utils.cpp
endef

MINISATIP_POST_PATCH_HOOKS += MINISATIP_REMOVE_STACKTRACE_CODE

$(eval $(cmake-package))

