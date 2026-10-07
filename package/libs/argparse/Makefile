#
# Copyright (C) 2026 OpenWrt buildroot contributors
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=argparse
PKG_VERSION:=3.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/p-ranav/argparse/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=9dcb3d8ce0a41b2a48ac8baa54b51a9f1b6a2c52dd374e28cc713bab0568ec98

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=OpenWrt buildroot contributors

include $(INCLUDE_DIR)/package.mk

define Package/argparse
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Argument parser for modern C++
  URL:=https://github.com/p-ranmar/argparse
  BUILDONLY:=1
endef

define Package/argparse/description
  Header-only command line argument parser for C++17 and later.
endef

define Build/Configure
endef

define Build/Compile
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/argparse
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/include/argparse/argparse.hpp $(1)/usr/include/argparse
endef

define Package/argparse/install
endef

$(eval $(call BuildPackage,argparse))
