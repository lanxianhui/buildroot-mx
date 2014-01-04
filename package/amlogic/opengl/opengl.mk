#############################################################
#
# opengl
#
#############################################################
OPENGL_VERSION=apiv17
OPENGL_SOURCE=opengl-$(OPENGL_VERSION).tar
OPENGL_SITE=$(TOPDIR)/package/amlogic/opengl/
OPENGL_SITE_METHOD=file
OPENGL_INSTALL_STAGING=YES
OPENGL_INSTALL_TARGET=YES

define OPENGL_INSTALL_STAGING_CMDS
	cp -a $(@D)/* $(STAGING_DIR);
endef

define OPENGL_INSTALL_TARGET_CMDS
	cp -a $(@D)/* $(TARGET_DIR);
endef

$(eval $(generic-package))