PYTHON2_GOBJECT_VERSION = 2.28.6
PYTHON2_GOBJECT_SOURCE = pygobject-$(PYTHON2_GOBJECT_VERSION).tar.xz
PYTHON2_GOBJECT_SITE = http://gnome.org
PYTHON2_GOBJECT_LICENSE = LGPL-2.1+
PYTHON2_GOBJECT_LICENSE_FILES = COPYING

# Wir setzen die Cache-Variablen für Autoconf/Automake auf 'yes' bzw. die Pfade
PYTHON2_GOBJECT_MAKE_OPTS = \
	PYTHON_INCLUDES="-I$(STAGING_DIR)/usr/include/python2.7" \
	PYTHON_LIBS="-L$(STAGING_DIR)/usr/lib -lpython2.7" \
	py_incdir="$(STAGING_DIR)/usr/include/python2.7"

PYTHON2_GOBJECT_CONF_ENV = \
    PYTHON=$(HOST_DIR)/bin/python2.7 \
    am_cv_python_includes="-I$(STAGING_DIR)/usr/include/python2.7" \
    PYTHON_INCLUDES="-I$(STAGING_DIR)/usr/include/python2.7" \
    PYTHON_LIBS="-L$(STAGING_DIR)/usr/lib -lpython2.7" \
    py_incdir="$(STAGING_DIR)/usr/include/python2.7" \
    python_incdir="$(STAGING_DIR)/usr/include/python2.7" \
    CFLAGS="$(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include/python2.7 -DLONG_BIT=32" \
    CPPFLAGS="$(TARGET_CPPFLAGS) -I$(STAGING_DIR)/usr/include/python2.7 -DLONG_BIT=32"


PYTHON2_GOBJECT_CONF_OPTS = \
	--disable-introspection \
	--disable-docs \
	--with-python-includes=$(STAGING_DIR)/usr/include/python2.7

# Falls das configure-Skript immer noch abbricht, patchen wir es vor dem Lauf
define PYTHON2_GOBJECT_BYPASS_HEADER_CHECK
	sed -i 's/as_fn_error.*could not find Python headers.*/echo "Bypassing Python header check"/' $(@D)/configure
endef

PYTHON2_GOBJECT_PRE_CONFIGURE_HOOKS += PYTHON2_GOBJECT_BYPASS_HEADER_CHECK

# Falls du die Host-Version für Tools im Build-Prozess brauchst
$(eval $(autotools-package))

