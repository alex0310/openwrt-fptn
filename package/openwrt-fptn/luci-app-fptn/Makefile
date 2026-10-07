#
# Copyright (C) 2026 developed by volunteers
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-fptn
PKG_VERSION:=0.4.5
PKG_RELEASE:=3

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/fptn-project/fptn/tar.gz/4d84f6bc61d0bb407cdd8548b53a09bffbceb4a8?
PKG_HASH:=a904405d79d69ee1c1390b95efc9555e1eb8737cbced586442d2f5b53352f367

PKG_BROTLI_VERSION:=1.2.0

define Download/brotli-js
  URL:=https://raw.githubusercontent.com/google/brotli/v$(PKG_BROTLI_VERSION)/js
  URL_FILE:=decode.min.js
  FILE:=brotli-decode.min.js
  HASH:=8a5348dbfb1a2873dbcb9a4d53f4a2d99638c113888b65b03cbb8ed86c7f7c27
endef

PKG_MAINTAINER:=Embedded Developer <dev@example.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

LUCI_FPTN:=0.4.5

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-fptn
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for FPTN
  URL:=https://github.com/fptn-project/fptn
  DEPENDS:=+luci-base +rpcd-mod-file +fptn-client
  PKGARCH:=all
endef

define Package/luci-app-fptn/description
  Web interface for the FPTN VPN client: connection status, settings and logs.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(TAR) -C $(PKG_BUILD_DIR) --strip-components=1 -xf $(DL_DIR)/$(PKG_SOURCE)
endef

define Build/Compile
endef

define Build/Install
	:
endef


define Package/luci-app-fptn/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/fptn
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/deploy/openwrt/data/luci/www/luci-static/resources/view/fptn/main.js \
		$(1)/www/luci-static/resources/view/fptn/main.js
	sed -i 's/@FPTN_VERSION@/$(LUCI_FPTN)/g' $(1)/www/luci-static/resources/view/fptn/main.js

	$(INSTALL_DIR) $(1)/www/luci-static/resources/fptn
	$(INSTALL_DATA) $(DL_DIR)/brotli-decode.min.js $(1)/www/luci-static/resources/fptn/brotli.js

	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/deploy/openwrt/data/luci/usr/share/luci/menu.d/luci-app-fptn.json \
		$(1)/usr/share/luci/menu.d/luci-app-fptn.json

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/deploy/openwrt/data/luci/usr/share/rpcd/acl.d/luci-app-fptn.json \
		$(1)/usr/share/rpcd/acl.d/luci-app-fptn.json
endef

$(eval $(call Download,brotli-js))
$(eval $(call BuildPackage,luci-app-fptn))
