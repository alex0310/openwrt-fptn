include $(TOPDIR)/rules.mk

PKG_NAME:=googletest
PKG_VERSION:=1.15.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/google/googletest/releases/download/v1.15.2/
PKG_HASH:=7b42b4d6ed48810c5362c265a17faebe90dc2373c885e5216439d37927f02926

PKG_MAINTAINER:=Vasek
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/googletest
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Google Testing Framework (GTest)
  URL:=https://github.com
  DEPENDS:=+libstdcpp
endef

define Package/googletest/description
  Google Testing and Mocking Framework.
endef

# Собираем GTest в режиме общих библиотек (.so), чтобы их видели другие пакеты CMake
CMAKE_OPTIONS += \
	-DBUILD_SHARED_LIBS=ON \
	-Dgtest_build_tests=OFF \
	-Dgmock_build_tests=OFF

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	# Копируем и gtest, и gmock библиотеки (.so)
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libg*.so* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/*.pc $(1)/usr/lib/pkgconfig/
	$(INSTALL_DIR) $(1)/usr/lib/cmake
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/cmake/* $(1)/usr/lib/cmake/
endef

define Package/googletest/install
	$(INSTALL_DIR) $(1)/usr/lib
	# Копируем все runtime-библиотеки на образ прошивки роутера
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libg*.so* $(1)/usr/lib/
endef


$(eval $(call BuildPackage,googletest))
