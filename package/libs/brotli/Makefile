include $(TOPDIR)/rules.mk

PKG_NAME:=brotli
PKG_VERSION:=1.1.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/google/brotli/archive/v1.1.0
PKG_HASH:=e720a6ca29428b803f4ad165371771f5398faba397edf6778837a18599ea13ff

PKG_MAINTAINER:=Vasek
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/brotli
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Brotli compression library
  URL:=https://github.com
  DEPENDS:=+libstdcpp
endef

define Package/brotli/description
  Brotli is a generic-purpose lossless compression algorithm.
endef

CMAKE_OPTIONS += \
	-DBUILD_SHARED_LIBS=ON \
	-DENABLE_LOG=OFF

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/brotli
	$(CP) $(PKG_BUILD_DIR)/c/include/brotli/*.h $(1)/usr/include/brotli/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libbrotli*.so* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/*.pc $(1)/usr/lib/pkgconfig/
endef

define Package/brotli/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libbrotli*.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,brotli))
