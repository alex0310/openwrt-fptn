include $(TOPDIR)/rules.mk

PKG_NAME:=yaff
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

PKG_SOURCE:=yaff-$(PKG_VERSION).tar.zst
PKG_SOURCE_URL:=https://github.com/alex0310/openwrt-fptn/releases/download/openwrt-sources
PKG_HASH:=49a4187769d332508ccd7b92e4617c3bfc8eb1644eabd0ddd8daaff7471c601e

PKG_MAINTAINER:=Embedded Developer <dev@example.com>
PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE

# Ссылаемся на ваш специфичный хостовый пакет protobuf29
PKG_BUILD_DEPENDS:=protobuf29/host

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/yaff
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Yandex Fast Format serialization library
  DEPENDS:=+libstdcpp
endef

define Package/yaff/description
  Библиотека сериализации YaFF от Yandex, необходимая для работы fptn-client.
endef

CMAKE_OPTIONS += \
	-DCMAKE_BUILD_TYPE=Release \
	-DYAFF_BUILD_TESTS=OFF \
	-DCMAKE_CXX_STANDARD=17 \
	-Dprotobuf_PROTOC_EXE=$(STAGING_DIR_HOSTPKG)/bin/protoc \
	-DProtobuf_PROTOC_EXECUTABLE=$(STAGING_DIR_HOSTPKG)/bin/protoc \
	-DCMAKE_PROGRAM_PATH=$(STAGING_DIR_HOSTPKG)/bin

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include/

	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/*.a $(1)/usr/lib/

	$(INSTALL_DIR) $(1)/usr/lib/cmake/YaFF
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/cmake/YaFF/YaFFGenerate.cmake $(1)/usr/lib/cmake/YaFF/
endef

define Package/yaff/install
	:
endef

HOST_CMAKE_OPTIONS += \
	-DCMAKE_BUILD_TYPE=Release \
	-DYAFF_BUILD_TESTS=OFF \
	-DYAFF_BUILD_BENCHMARKS=OFF \
	-DYAFF_BUILD_EXAMPLES=OFF \
	-DProtobuf_DIR=$(STAGING_DIR_HOSTPKG)/lib/cmake/protobuf

define Host/Install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) $(HOST_BUILD_DIR)/src/protoc-plugin/protoc-gen-yaff $(1)/bin/
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,yaff))
