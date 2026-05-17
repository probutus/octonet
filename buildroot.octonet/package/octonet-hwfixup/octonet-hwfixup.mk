OCTONET_HWFIXUP_VERSION = 1.0
# Da dein Quellcode in ../../octonet-hwfixup liegt, mappen wir das relativ zum External-Tree:
OCTONET_HWFIXUP_SITE = ../octonet-hwfixup
OCTONET_HWFIXUP_SITE_METHOD = local
OCTONET_HWFIXUP_LICENSE = GPL-2.0

$(eval $(kernel-module))
$(eval $(generic-package))
