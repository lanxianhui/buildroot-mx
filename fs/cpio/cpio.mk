################################################################################
#
# cpio to archive target filesystem
#
################################################################################

ifeq ($(BR2_ROOTFS_DEVICE_CREATION_STATIC),y)

define ROOTFS_CPIO_ADD_INIT
        if [ ! -e $(TARGET_DIR)/init ]; then \
                ln -sf sbin/init $(TARGET_DIR)/init; \
        fi
endef

else
# devtmpfs does not get automounted when initramfs is used.
# Add a pre-init script to mount it before running init

ifneq ($(BR2_TARGET_ROOTFS_INITRAMFS_INIT),"")
INITRAMFS_INIT = $(BR2_TARGET_ROOTFS_INITRAMFS_INIT)
else
INITRAMFS_INIT = fs/cpio/init
endif

define ROOTFS_CPIO_ADD_INIT
        if [ ! -e $(INITRAMFS_INIT) ]; then \
                $(INSTALL) -m 0755 $(INITRAMFS_INIT) $(TARGET_DIR)/init; \
        fi
endef

PACKAGES_PERMISSIONS_TABLE += /dev/console c 622 0 0 5 1 - - -$(sep)

endif # BR2_ROOTFS_DEVICE_CREATION_STATIC

ROOTFS_CPIO_PRE_GEN_HOOKS += ROOTFS_CPIO_ADD_INIT


ifneq ($(BR2_TARGET_ROOTFS_INITRAMFS_LIST),"")
define ROOTFS_CPIO_CMD
	cd $(TARGET_DIR) && cat $(CONFIG_DIR)/$(BR2_TARGET_ROOTFS_INITRAMFS_LIST) | cpio --quiet -o -H newc > $@
endef
else
define ROOTFS_CPIO_CMD
	cd $(TARGET_DIR) && find . | cpio --quiet -o -H newc > $@
endef
endif # BR2_TARGET_ROOTFS_INITRAMFS_LIST

$(BINARIES_DIR)/rootfs.cpio.uboot: $(BINARIES_DIR)/rootfs.cpio host-uboot-tools
	$(MKIMAGE) -A $(MKIMAGE_ARCH) -T ramdisk \
		-C none -d $<$(ROOTFS_CPIO_COMPRESS_EXT) $@

ifeq ($(BR2_TARGET_ROOTFS_CPIO_UIMAGE),y)
ROOTFS_CPIO_POST_TARGETS += $(BINARIES_DIR)/rootfs.cpio.uboot
endif

$(eval $(call ROOTFS_TARGET,cpio))
