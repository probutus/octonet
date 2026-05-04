################################################################################
#
# python
#
################################################################################

PYTHON2_VERSION_MAJOR = 2.7
PYTHON2_VERSION = $(PYTHON2_VERSION_MAJOR).18
PYTHON2_SOURCE = Python-$(PYTHON2_VERSION).tar.xz
PYTHON2_SITE = https://python.org/ftp/python/$(PYTHON2_VERSION)
PYTHON2_LICENSE = Python-2.0, others
PYTHON2_LICENSE_FILES = LICENSE
PYTHON2_CPE_ID_VENDOR = python
PYTHON2_LIBTOOL_PATCH = NO

# Python needs itself to be built, so in order to cross-compile
# Python, we need to build a host Python first. This host Python is
# also installed in $(HOST_DIR), as it is needed when cross-compiling
# third-party Python modules.

HOST_PYTHON2_CONF_OPTS += \
	--enable-static \
	--without-cxx-main \
	--disable-sqlite3 \
	--disable-tk \
	--with-expat=system \
	--with-system-ffi \
	--disable-curses \
	--disable-codecs-cjk \
	--disable-nis \
	--enable-unicodedata \
	--disable-dbm \
	--disable-gdbm \
	--disable-bsddb \
	--disable-test-modules \
	--disable-bz2 \
	--disable-ossaudiodev \
	--disable-pyo-build

# Make sure that LD_LIBRARY_PATH overrides -rpath.
# This is needed because libpython may be installed at the same time that
# python is called.
# Make python believe we don't have 'hg' and 'svn', so that it doesn't
# try to communicate over the network during the build.
HOST_PYTHON2_CONF_ENV += \
	LDFLAGS="$(HOST_LDFLAGS) -Wl,--enable-new-dtags" \
	ac_cv_prog_HAS_HG=/bin/false \
	ac_cv_prog_SVNVERSION=/bin/false

# Building host python in parallel sometimes triggers a "Bus error"
# during the execution of "./python setup.py build" in the
# installation step. It is probably due to the installation of a
# shared library taking place in parallel to the execution of
# ./python, causing spurious Bus error. Building host-python with
# MAKE1 has shown to workaround the problem.
HOST_PYTHON2_MAKE = $(MAKE1)

PYTHON2_DEPENDENCIES = host-python2 libffi $(TARGET_NLS_DEPENDENCIES)

HOST_PYTHON2_DEPENDENCIES = host-expat host-libffi host-zlib

ifeq ($(BR2_PACKAGE_HOST_PYTHON2_SSL),y)
HOST_PYTHON2_DEPENDENCIES += host-openssl
else
HOST_PYTHON2_CONF_OPTS += --disable-ssl
endif

PYTHON2_INSTALL_STAGING = YES

ifeq ($(BR2_PACKAGE_PYTHON2_READLINE),y)
PYTHON2_DEPENDENCIES += readline
else
PYTHON2_CONF_OPTS += --disable-readline
endif

ifeq ($(BR2_PACKAGE_PYTHON2_CURSES),y)
PYTHON2_DEPENDENCIES += ncurses
else
PYTHON2_CONF_OPTS += --disable-curses
endif

ifeq ($(BR2_PACKAGE_PYTHON2_PYEXPAT),y)
PYTHON2_DEPENDENCIES += expat
PYTHON2_CONF_OPTS += --with-expat=system
else
PYTHON2_CONF_OPTS += --with-expat=none
endif

ifeq ($(BR2_PACKAGE_PYTHON2_BSDDB),y)
PYTHON2_DEPENDENCIES += berkeleydb
else
PYTHON2_CONF_OPTS += --disable-bsddb
endif

ifeq ($(BR2_PACKAGE_PYTHON2_SQLITE),y)
PYTHON2_DEPENDENCIES += sqlite
else
PYTHON2_CONF_OPTS += --disable-sqlite3
endif

ifeq ($(BR2_PACKAGE_PYTHON2_SSL),y)
PYTHON2_DEPENDENCIES += openssl
else
PYTHON2_CONF_OPTS += --disable-ssl
endif

ifneq ($(BR2_PACKAGE_PYTHON2_CODECSCJK),y)
PYTHON2_CONF_OPTS += --disable-codecs-cjk
endif

ifneq ($(BR2_PACKAGE_PYTHON2_UNICODEDATA),y)
PYTHON2_CONF_OPTS += --disable-unicodedata
endif

# Default is UCS2 w/o a conf opt
ifeq ($(BR2_PACKAGE_PYTHON2_UCS4),y)
# host-python must have the same UCS2/4 configuration as the target
# python
HOST_PYTHON2_CONF_OPTS += --enable-unicode=ucs4
PYTHON2_CONF_OPTS += --enable-unicode=ucs4
endif

ifeq ($(BR2_PACKAGE_PYTHON2_2TO3),y)
PYTHON2_CONF_OPTS += --enable-lib2to3
else
PYTHON2_CONF_OPTS += --disable-lib2to3
endif

ifeq ($(BR2_PACKAGE_PYTHON2_BZIP2),y)
PYTHON2_DEPENDENCIES += bzip2
else
PYTHON2_CONF_OPTS += --disable-bz2
endif

ifeq ($(BR2_PACKAGE_PYTHON2_ZLIB),y)
PYTHON2_DEPENDENCIES += zlib
else
PYTHON2_CONF_OPTS += --disable-zlib
endif

ifeq ($(BR2_PACKAGE_PYTHON2_HASHLIB),y)
PYTHON2_DEPENDENCIES += openssl
else
PYTHON2_CONF_OPTS += --disable-hashlib
endif

ifeq ($(BR2_PACKAGE_PYTHON2_OSSAUDIODEV),y)
PYTHON2_CONF_OPTS += --enable-ossaudiodev
else
PYTHON2_CONF_OPTS += --disable-ossaudiodev
endif

# Make python believe we don't have 'hg' and 'svn', so that it doesn't
# try to communicate over the network during the build.
PYTHON2_CONF_ENV += \
	ac_cv_have_long_long_format=yes \
	ac_cv_file__dev_ptmx=yes \
	ac_cv_file__dev_ptc=yes \
	ac_cv_working_tzset=yes \
	ac_cv_prog_HAS_HG=/bin/false \
	ac_cv_prog_SVNVERSION=/bin/false

# GCC is always compliant with IEEE754
ifeq ($(BR2_ENDIAN),"LITTLE")
PYTHON2_CONF_ENV += ac_cv_little_endian_double=yes
else
PYTHON2_CONF_ENV += ac_cv_big_endian_double=yes
endif

PYTHON2_CONF_OPTS += \
	--without-cxx-main \
	--without-doc-strings \
	--with-system-ffi \
	--disable-pydoc \
	--disable-test-modules \
	--disable-gdbm \
	--disable-tk \
	--disable-nis \
	--disable-dbm \
	--disable-pyo-build \
	--disable-pyc-build

# This is needed to make sure the Python build process doesn't try to
# regenerate those files with the pgen program. Otherwise, it builds
# pgen for the target, and tries to run it on the host.

define PYTHON2_TOUCH_GRAMMAR_FILES
	touch $(@D)/Include/graminit.h $(@D)/Python/graminit.c
endef

PYTHON2_POST_PATCH_HOOKS += PYTHON2_TOUCH_GRAMMAR_FILES

#
# Remove useless files. In the config/ directory, only the Makefile
# and the pyconfig.h files are needed at runtime.
#
# idle & smtpd.py have bad shebangs and are mostly samples
#
define PYTHON2_REMOVE_USELESS_FILES
	rm -f $(TARGET_DIR)/usr/bin/python$(PYTHON2_VERSION_MAJOR)-config
	rm -f $(TARGET_DIR)/usr/bin/python2-config
	rm -f $(TARGET_DIR)/usr/bin/python-config
	rm -f $(TARGET_DIR)/usr/bin/smtpd.py
	rm -f $(TARGET_DIR)/usr/lib/python$(PYTHON2_VERSION_MAJOR)/distutils/command/wininst*.exe
	for i in `find $(TARGET_DIR)/usr/lib/python$(PYTHON2_VERSION_MAJOR)/config/ \
		-type f -not -name pyconfig.h -a -not -name Makefile` ; do \
		rm -f $$i ; \
	done
endef

PYTHON2_POST_INSTALL_TARGET_HOOKS += PYTHON2_REMOVE_USELESS_FILES

#
# Make sure libpython gets stripped out on target
#
define PYTHON2_ENSURE_LIBPYTHON_STRIPPED
	chmod u+w $(TARGET_DIR)/usr/lib/libpython$(PYTHON2_VERSION_MAJOR)*.so
endef

PYTHON2_POST_INSTALL_TARGET_HOOKS += PYTHON2_ENSURE_LIBPYTHON_STRIPPED

# Always install the python symlink in the target tree
define PYTHON2_INSTALL_TARGET_PYTHON_SYMLINK
	ln -sf python2 $(TARGET_DIR)/usr/bin/python
endef

PYTHON2_POST_INSTALL_TARGET_HOOKS += PYTHON2_INSTALL_TARGET_PYTHON_SYMLINK

# Always install the python-config symlink in the staging tree
define PYTHON2_INSTALL_STAGING_PYTHON_CONFIG_SYMLINK
	ln -sf python2-config $(STAGING_DIR)/usr/bin/python-config
endef

PYTHON2_POST_INSTALL_STAGING_HOOKS += PYTHON2_INSTALL_STAGING_PYTHON_CONFIG_SYMLINK

PYTHON2_AUTORECONF = YES

# Some packages may have build scripts requiring python2.
# Only install the python symlink in the host tree if python3 is not enabled
# for the target, otherwise the default python program may be missing.
ifneq ($(BR2_PACKAGE_PYTHON3),y)
define HOST_PYTHON2_INSTALL_PYTHON_SYMLINK
	ln -sf python2 $(HOST_DIR)/bin/python
	ln -sf python2-config $(HOST_DIR)/bin/python-config
endef

HOST_PYTHON2_POST_INSTALL_HOOKS += HOST_PYTHON2_INSTALL_PYTHON_SYMLINK
endif

# Provided to other packages
PYTHON2_PATH = $(STAGING_DIR)/usr/lib/python$(PYTHON2_VERSION_MAJOR)/sysconfigdata/

$(eval $(autotools-package))
$(eval $(host-autotools-package))

ifeq ($(BR2_REPRODUCIBLE),y)
define PYTHON2_FIX_TIME
	find $(TARGET_DIR)/usr/lib/python$(PYTHON2_VERSION_MAJOR) -name '*.py' -print0 | \
		xargs -0 --no-run-if-empty touch -d @$(SOURCE_DATE_EPOCH)
endef
endif

define PYTHON2_CREATE_PYC_FILES
	$(PYTHON2_FIX_TIME)
	PYTHONPATH="$(PYTHON2_PATH)" \
	$(HOST_DIR)/bin/python$(PYTHON2_VERSION_MAJOR) \
		$(PYTHON2_PKGDIR)/pycompile.py \
		$(if $(VERBOSE),--verbose) \
		--strip-root $(TARGET_DIR) \
		$(TARGET_DIR)/usr/lib/python$(PYTHON2_VERSION_MAJOR)
endef

ifeq ($(BR2_PACKAGE_PYTHON2_PYC_ONLY)$(BR2_PACKAGE_PYTHON2_PY_PYC),y)
PYTHON2_TARGET_FINALIZE_HOOKS += PYTHON2_CREATE_PYC_FILES
endif

ifeq ($(BR2_PACKAGE_PYTHON2_PYC_ONLY),y)
define PYTHON2_REMOVE_PY_FILES
	find $(TARGET_DIR)/usr/lib/python$(PYTHON2_VERSION_MAJOR) -name '*.py' \
		$(if $(strip $(KEEP_PYTHON_PY_FILES)),-not \( $(call finddirclauses,$(TARGET_DIR),$(KEEP_PYTHON_PY_FILES)) \) ) \
		-print0 | \
		xargs -0 --no-run-if-empty rm -f
endef
PYTHON2_TARGET_FINALIZE_HOOKS += PYTHON2_REMOVE_PY_FILES
endif

# Normally, *.pyc files should not have been compiled, but just in
# case, we make sure we remove all of them.
ifeq ($(BR2_PACKAGE_PYTHON2_PY_ONLY),y)
define PYTHON2_REMOVE_PYC_FILES
	find $(TARGET_DIR)/usr/lib/python$(PYTHON2_VERSION_MAJOR) -name '*.pyc' -print0 | \
		xargs -0 --no-run-if-empty rm -f
endef
PYTHON2_TARGET_FINALIZE_HOOKS += PYTHON2_REMOVE_PYC_FILES
endif

# In all cases, we don't want to keep the optimized .pyo files
define PYTHON2_REMOVE_PYO_FILES
	find $(TARGET_DIR)/usr/lib/python$(PYTHON2_VERSION_MAJOR) -name '*.pyo' -print0 | \
		xargs -0 --no-run-if-empty rm -f
endef
PYTHON2_TARGET_FINALIZE_HOOKS += PYTHON2_REMOVE_PYO_FILES
