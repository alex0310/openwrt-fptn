include $(TOPDIR)/rules.mk

PKG_NAME:=spdlog
PKG_VERSION:=1.12.0
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/gabime/spdlog/tar.gz/v1.12.0?
PKG_HASH:=4dccf2d10f410c1e2feaff89966bfc49a1abb29ef6f08246335b110e001e09a9

PKG_MAINTAINER:=Vasek
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

# ФОРСИРУЕМ СТАНДАРТ C++20 ДЛЯ ВСЕХ МАКРОСОВ СБОРКИ OPENWRT
TARGET_CXXFLAGS += -std=c++20

define Package/libspdlog
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Fast C++ logging library
  URL:=https://github.com
  DEPENDS:=+libstdcpp
endef

define Package/libspdlog/description
  Very fast, header-only or compiled, C++ logging library.
endef

# Отключаем внешний fmt, чтобы убрать ошибку переопределения to_string_view
CMAKE_OPTIONS += \
	-DSPDLOG_BUILD_SHARED=ON \
	-DSPDLOG_FMT_EXTERNAL=OFF \
	-DSPDLOG_BUILD_BENCH=OFF \
	-DSPDLOG_BUILD_TESTS=OFF \
	-DCMAKE_CXX_STANDARD=20 \
	-DCMAKE_CXX_STANDARD_REQUIRED=ON

define Build/Configure
	$(Build/Configure/Default)
	# ЖЕСТКИЙ СЕДАН: если скрипты генерации всё равно записали c++11/c++14, перезаписываем файлы конфигурации Ninja
	find $(PKG_BUILD_DIR) -name "flags.make" -o -name "build.ninja" -exec sed -i 's/-std=c++11/-std=c++20/g' {} \; 2>/dev/null || true
	find $(PKG_BUILD_DIR) -name "flags.make" -o -name "build.ninja" -exec sed -i 's/-std=gnu++11/-std=c++20/g' {} \; 2>/dev/null || true
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/spdlog $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libspdlog*.so* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/*.pc $(1)/usr/lib/pkgconfig/
	$(INSTALL_DIR) $(1)/usr/lib/cmake/spdlog
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/cmake/spdlog/*.cmake $(1)/usr/lib/cmake/spdlog/
endef

define Package/libspdlog/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libspdlog*.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libspdlog))
