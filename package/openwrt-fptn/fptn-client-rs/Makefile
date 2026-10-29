#
# FPTN VPN client — Rust port.
#
# This package ships a *prebuilt* static-musl binary rather than building Rust
# inside the OpenWrt buildroot: `mipsel-unknown-linux-musl` is a tier-3 target
# that needs `-Z build-std`, which the buildroot's cargo integration cannot do,
# and pulling in the full rust toolchain would add tens of minutes to CI for no
# benefit to the image. The artifact is cross-built with
# `scripts/build-mipsel.sh` (zigbuild) and staged into ./files/ beforehand.
#
# Copyright (C) 2026 developed by volunteers
# SPDX-License-Identifier: MIT
#

include $(TOPDIR)/rules.mk

PKG_NAME:=fptn-client-rs
PKG_VERSION:=0.1.6
PKG_RELEASE:=1

PKG_MAINTAINER:=Vasek
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/fptn-client-rs
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  TITLE:=FPTN VPN client (Rust port)
  URL:=https://github.com/fptn-project/fptn
  # Satisfies luci-app-fptn's `+fptn-client` dependency, like fptn-client-slim.
  PROVIDES:=fptn-client
  # The C++ clients install the very same /etc/init.d/fptn + /etc/config/fptn.
  CONFLICTS:=fptn-client fptn-client-slim
  DEPENDS:=+kmod-tun +ip-full
endef

define Package/fptn-client-rs/description
  FPTN is a fast and lightweight VPN protocol with anti-censorship features.
  This package provides the static Rust client (fptn-client-rs) and the TCP
  latency probe (fptn-tcp-probe) used by the LuCI app. Drop-in replacement for
  fptn-client-slim: same UCI schema, same procd service, no C++ runtime deps.
endef

# No source to download: the (prebuilt) binaries must be staged into ./files/.
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
	@for f in fptn-client-rs fptn-tcp-probe; do \
		if [ ! -s "./files/$$f" ]; then \
			echo "ERROR: ./files/$$f is missing."; \
			echo "Cross-build it first, e.g. from the fptn-client-rs repo:"; \
			echo "    scripts/stage-openwrt.sh $(CURDIR)"; \
			exit 1; \
		fi; \
	done
endef

define Package/fptn-client-rs/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/fptn-client-rs $(1)/usr/bin/fptn-client-rs
	$(INSTALL_BIN) ./files/fptn-tcp-probe $(1)/usr/bin/fptn-tcp-probe

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/fptn.init $(1)/etc/init.d/fptn

	# LuCI stores the custom split-tunnel domain list here.
	$(INSTALL_DIR) $(1)/etc/fptn

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/99-fptn $(1)/etc/uci-defaults/99-fptn

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/fptn.config $(1)/etc/config/fptn
endef

define Package/fptn-client-rs/conffiles
/etc/config/fptn
endef

$(eval $(call BuildPackage,fptn-client-rs))
