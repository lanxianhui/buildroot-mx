#############################################################
#
# tar + squashfs to archive target filesystem
#
#############################################################

ROOTFS_RECOVERY_AML_DEPENDENCIES = linux rootfs-tar_aml host-python

RECOVERY_AML_ARGS = -b $(BR2_TARGET_ROOTFS_RECOVERY_AML_BOARDNAME)
ifeq ($(BR2_TARGET_ROOTFS_RECOVERY_AML_WIPE_USERDATA),y)
  RECOVERY_AML_ARGS += -w
endif
ifeq ($(BR2_TARGET_ROOTFS_RECOVERY_AML_WIPE_USERDATA_CONDITIONAL),y)
  RECOVERY_AML_ARGS += -c
endif

# Introduce imgpack
ifeq ($(BR2_TARGET_ROOTFS_RECOVERY_AML_IMGPACK), y)

# We set default folder for res_pack resources
RES_PACK = fs/recovery_aml/res_pack

# Change it if custom folder is specified
ifneq ($(strip $(BR2_TARGET_ROOTFS_RECOVERY_AML_IMGPACK_CUSTOM)),"")
RES_PACK = $(BR2_TARGET_ROOTFS_RECOVERY_AML_IMGPACK_CUSTOM)
endif

RECOVERY_AML_ARGS += -l yes

endif

# Define default file name for package
UPDATE_ZIP = $(BR2_TARGET_ROOTFS_RECOVERY_AML_BOARDNAME)-$(shell date -u +%0d%^b%Y-%H%M%S)-update.zip

ifeq ($(BR2_TARGET_ROOTFS_RECOVERY_AML_UPDATE_ZIP_NAME_SHORT_DATE),y)
    UPDATE_ZIP = $(BR2_TARGET_ROOTFS_RECOVERY_AML_BOARDNAME)-$(shell date -u +%Y%m%d)-update.zip
endif
ifeq ($(BR2_TARGET_ROOTFS_RECOVERY_AML_UPDATE_ZIP_NAME_BOARDNAME_UPDATE_ZIP),y)
    UPDATE_ZIP = $(BR2_TARGET_ROOTFS_RECOVERY_AML_BOARDNAME)-update.zip
endif
ifeq ($(BR2_TARGET_ROOTFS_RECOVERY_AML_UPDATE_ZIP_NAME_UPDATE_ZIP),y)
    UPDATE_ZIP = update.zip
endif

ifneq ($(strip $(BR2_TARGET_ROOTFS_RECOVERY_AML_LOGO)),"")
AML_LOGO = $(BR2_TARGET_ROOTFS_RECOVERY_AML_LOGO)
else
AML_LOGO = fs/recovery_aml/aml_logo.img
endif

ifneq ($(BR2_TARGET_ROOTFS_RECOVERY_AML_IMGPACK),y)

define ROOTFS_RECOVERY_AML_CMD
 mkdir -p $(BINARIES_DIR)/aml_recovery/system && \
 tar -C $(BINARIES_DIR)/aml_recovery/system -xf $(BINARIES_DIR)/rootfs.tar && \
 mkdir -p $(BINARIES_DIR)/aml_recovery/META-INF/com/google/android/ && \
 PYTHONDONTWRITEBYTECODE=1 $(HOST_DIR)/usr/bin/python fs/recovery_aml/android_scriptgen $(RECOVERY_AML_ARGS) -i -p $(BINARIES_DIR)/aml_recovery/system -o \
   $(BINARIES_DIR)/aml_recovery/META-INF/com/google/android/updater-script && \
 cp -f fs/recovery_aml/update-binary $(BINARIES_DIR)/aml_recovery/META-INF/com/google/android/ && \
 cp -f fs/recovery_aml/aml_logo.img $(BINARIES_DIR)/aml_recovery/ && \
 cp -f $(BINARIES_DIR)/uImage $(BINARIES_DIR)/aml_recovery/ && \
 find $(BINARIES_DIR)/aml_recovery/system/ -type l -delete && \
 find $(BINARIES_DIR)/aml_recovery/system/ -type d -empty -exec sh -c 'echo "dummy" > "{}"/.empty' \; && \
 pushd $(BINARIES_DIR)/aml_recovery/ >/dev/null && \
 zip -m -q -r -y $(BINARIES_DIR)/aml_recovery/update-unsigned.zip aml_logo.img uImage META-INF system && \
 popd >/dev/null && \
 echo "Signing $(UPDATE_ZIP)..." && \
 pushd fs/recovery_aml/ >/dev/null; java -Xmx1024m -jar signapk.jar -w testkey.x509.pem testkey.pk8 $(BINARIES_DIR)/aml_recovery/update-unsigned.zip $(BINARIES_DIR)/$(UPDATE_ZIP) && \
 rm -rf $(BINARIES_DIR)/aml_recovery; rm -f $(TARGET_DIR)/usr.sqsh
endef

else

define ROOTFS_RECOVERY_AML_CMD
 mkdir -p $(BINARIES_DIR)/aml_recovery/system && \
 echo "Creating logo.img..." && \
 fs/recovery_aml/imgpack -r $(RES_PACK) $(BINARIES_DIR)/aml_recovery/logo.img && \
 tar -C $(BINARIES_DIR)/aml_recovery/system -xf $(BINARIES_DIR)/rootfs.tar && \
 mkdir -p $(BINARIES_DIR)/aml_recovery/META-INF/com/google/android/ && \
 PYTHONDONTWRITEBYTECODE=1 $(HOST_DIR)/usr/bin/python fs/recovery_aml/android_scriptgen $(RECOVERY_AML_ARGS) -i -p $(BINARIES_DIR)/aml_recovery/system -o \
   $(BINARIES_DIR)/aml_recovery/META-INF/com/google/android/updater-script && \
 cp -f fs/recovery_aml/update-binary $(BINARIES_DIR)/aml_recovery/META-INF/com/google/android/ && \
 cp -f $(AML_LOGO) $(BINARIES_DIR)/aml_recovery/aml_logo.img && \
 cp -f $(BINARIES_DIR)/uImage $(BINARIES_DIR)/aml_recovery/ && \
 find $(BINARIES_DIR)/aml_recovery/system/ -type l -delete && \
 find $(BINARIES_DIR)/aml_recovery/system/ -type d -empty -exec sh -c 'echo "dummy" > "{}"/.empty' \; && \
 pushd $(BINARIES_DIR)/aml_recovery/ >/dev/null && \
 zip -m -q -r -y $(BINARIES_DIR)/aml_recovery/update-unsigned.zip logo.img aml_logo.img uImage META-INF system && \
 popd >/dev/null && \
 echo "Signing $(UPDATE_ZIP)..." && \
 pushd fs/recovery_aml/ >/dev/null; java -Xmx1024m -jar signapk.jar -w testkey.x509.pem testkey.pk8 $(BINARIES_DIR)/aml_recovery/update-unsigned.zip $(BINARIES_DIR)/$(UPDATE_ZIP) && \
 rm -rf $(BINARIES_DIR)/aml_recovery; rm -f $(TARGET_DIR)/usr.sqsh
endef

endif

$(eval $(call ROOTFS_TARGET,recovery_aml))
