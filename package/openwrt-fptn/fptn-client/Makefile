#
# Copyright (C) 2026 developed by volunteers
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=fptn-client
PKG_VERSION:=0.4.5
PKG_RELEASE:=3

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/fptn-project/fptn.git
PKG_SOURCE_VERSION:=4d84f6bc61d0bb407cdd8548b53a09bffbceb4a8
PKG_HASH:=374bd9b523e883fb4ad650c40ae625738186377f542d8359a3b6d9dd426032eb

PKG_MAINTAINER:=developed by volunteers
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=protobuf29/host yaff boringssl argparse libfmt spdlog brotli boost icu libre2 libidn2 nlohmannjson protobuf zlib

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

TARGET_LDFLAGS += -Wl,-rpath-link,$(STAGING_DIR)/usr/lib

define Package/fptn-client
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
TITLE:=FPTN Console VPN Client
URL:=https://github.com/fptn-project/fptn

PROVIDES:=libre2.so.11 libprotobuf.so.29.5.0 libutf8_validity.so
  DEPENDS:=+libstdcpp +libpthread +libatomic \
	+icu +libidn2 +zlib \
	+kmod-tun +ip-full
endef

define Package/fptn-client/description
  FPTN is a fast and lightweight VPN protocol with anti-censorship features.
  This package provides the command line client.
endef

BORINGSSL_DIR:=$(shell find $(BUILD_DIR) -maxdepth 2 -type d -name "boringssl-*" | head -n 1)

BROTLI_VERSION:=1.1.0
YAFF_LIB_DIR:=$(STAGING_DIR)/usr/lib
YAFF_HOST_PLUGIN:=$(STAGING_DIR_HOSTPKG)/bin/protoc-gen-yaff
YAFF_GENERATE_MODULE:=$(STAGING_DIR)/usr/lib/cmake/YaFF/YaFFGenerate.cmake

CMAKE_OPTIONS += \
	-DFPTN_VERSION=$(PKG_VERSION) \
	-DFPTN_OPENWRT=ON \
	-DFPTN_BUILD_ONLY_FPTN_LIB=OFF \
	-DFPTN_BUILD_WITH_GUI_CLIENT=OFF \
	-DFPTN_VERSION_STRING=$(PKG_VERSION) \
	-DProtobuf_PROTOC_EXECUTABLE=$(STAGING_DIR_HOSTPKG)/bin/protoc \
	-Dprotobuf_MODULE_COMPATIBLE=ON \
	-DCMAKE_PROGRAM_PATH=$(STAGING_DIR_HOSTPKG)/bin \
	-DBROTLI_INCLUDE_DIR=$(STAGING_DIR)/usr/include \
	-DBROTLI_DEC_LIB=$(PKG_BUILD_DIR)/brotli-static/libbrotlidec.a \
	-DBROTLI_ENC_LIB=$(STAGING_DIR)/usr/lib/libbrotlienc.so \
	-DBROTLI_COMMON_LIB=$(PKG_BUILD_DIR)/brotli-static/libbrotlicommon.a \
	-DBoost_NO_BOOST_CMAKE=ON \
	-DBoost_USE_STATIC_LIBS=ON \
	-DBUILD_TESTING=OFF \
	-DENABLE_TESTING=OFF \
	-DENABLE_TESTS=OFF \
	-DBUILD_BENCHMARKS=OFF \
	-DCMAKE_BUILD_TYPE=Release \
	-Dcamouflagetls_BUILD_TESTS=OFF \
	-DCAMOUFLAGETLS_BUILD_TESTS=OFF \
	-DOPENSSL_ROOT_DIR=$(BORINGSSL_DIR) \
	-DOPENSSL_INCLUDE_DIR=$(BORINGSSL_DIR)/include \
	-DOPENSSL_SSL_LIBRARY=$(BORINGSSL_DIR)/libssl.a \
	-DOPENSSL_CRYPTO_LIBRARY=$(BORINGSSL_DIR)/libcrypto.a \
	-DOPENSSL_USE_STATIC_LIBS=ON \
	-DYaFF_DIR=$(PKG_BUILD_DIR)/cmake_fake \
	-Dspdlog_DIR=$(PKG_BUILD_DIR)/cmake_fake \
	-Dfmt_DIR=$(PKG_BUILD_DIR)/cmake_fake \
	-DCMAKE_PREFIX_PATH=$(PKG_BUILD_DIR)/cmake_fake \
	-DCMAKE_CXX_FLAGS_RELEASE="-DNDEBUG -Wno-error -Wno-missing-requires -I$(PKG_BUILD_DIR)/fmt_shim -I$(BORINGSSL_DIR)/include -I$(STAGING_DIR)/usr/include" \
	-DCMAKE_CXX_LINK_EXECUTABLE="<CMAKE_CXX_COMPILER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> -L$(BORINGSSL_DIR) -Wl,--start-group <LINK_LIBRARIES> -l:libssl.a -l:libcrypto.a $(YAFF_LIB_DIR)/libyaff_proto.a $(foreach l,date_time context regex charconv thread chrono atomic container,$(STAGING_DIR)/usr/lib/libboost_$(l).a) $(STAGING_DIR)/usr/lib/libicuuc.so $(STAGING_DIR)/usr/lib/libicui18n.so $(STAGING_DIR)/usr/lib/libicudata.so -Wl,--end-group -lpthread -ldl"

define Package/fptn-client/fptn_sanitizers_strip
	find $(PKG_BUILD_DIR) -type f \
		\( -name "*.make" -o -name "*.ninja" -o -name "*.txt" -o -name "*.cmake" -o -name "*.mak" \) \
		-exec sed -i -e 's/-Wformat-security//g' \
		          -e 's/=format-security//g' \
		          -e 's/-Wformat //g' \
		          -e 's/-Werror=missing-requires//g' \
		          -e 's/-pedantic//g' \
		          -e 's/-Werror//g' {} \; 2>/dev/null || true
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	$(foreach l,atomic charconv chrono container context coroutine date_time exception fiber filesystem locale nowide process random regex thread,ar s $(STAGING_DIR)/usr/lib/libboost_$(l).a)
	mkdir -p $(PKG_BUILD_DIR)/brotli-src
	$(TAR) -C $(PKG_BUILD_DIR)/brotli-src --strip-components=1 -xf \
		$(DL_DIR)/brotli-$(BROTLI_VERSION).tar.gz
	mkdir -p $(PKG_BUILD_DIR)/brotli-static/dec
	mkdir -p $(PKG_BUILD_DIR)/brotli-static/common
	cd $(PKG_BUILD_DIR)/brotli-static/dec && \
		$(TARGET_CC) -O2 -fPIC -DBROTLI_BUILD_PORTABLE \
			-I$(PKG_BUILD_DIR)/brotli-src/c/include -c \
			$(PKG_BUILD_DIR)/brotli-src/c/dec/bit_reader.c \
			$(PKG_BUILD_DIR)/brotli-src/c/dec/decode.c \
			$(PKG_BUILD_DIR)/brotli-src/c/dec/huffman.c \
			$(PKG_BUILD_DIR)/brotli-src/c/dec/state.c
	cd $(PKG_BUILD_DIR)/brotli-static/common && \
		$(TARGET_CC) -O2 -fPIC -DBROTLI_BUILD_PORTABLE \
			-I$(PKG_BUILD_DIR)/brotli-src/c/include -c \
			$(PKG_BUILD_DIR)/brotli-src/c/common/constants.c \
			$(PKG_BUILD_DIR)/brotli-src/c/common/context.c \
			$(PKG_BUILD_DIR)/brotli-src/c/common/dictionary.c \
			$(PKG_BUILD_DIR)/brotli-src/c/common/platform.c \
			$(PKG_BUILD_DIR)/brotli-src/c/common/shared_dictionary.c \
			$(PKG_BUILD_DIR)/brotli-src/c/common/transform.c
	cd $(PKG_BUILD_DIR)/brotli-static && \
		$(AR) rcs libbrotlicommon.a common/*.o && \
		$(AR) rcs libbrotlidec.a dec/*.o
endef


define Build/Configure
	mkdir -p $(PKG_BUILD_DIR)/cmake_fake
	printf '%s\n' \
		'set(argparse_FOUND TRUE CACHE BOOL "" FORCE)' \
		'add_library(argparse::argparse INTERFACE IMPORTED)' \
		'set_target_properties(argparse::argparse PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "$(STAGING_DIR)/usr/include")' \
		> $(PKG_BUILD_DIR)/cmake_fake/argparseConfig.cmake

	printf '%s\n' \
		'set(nlohmann_json_FOUND TRUE CACHE BOOL "" FORCE)' \
		'add_library(nlohmann_json::nlohmann_json INTERFACE IMPORTED)' \
		'set_target_properties(nlohmann_json::nlohmann_json PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "$(STAGING_DIR)/usr/include")' \
		'set(nlohmann_json_INCLUDE_DIRS "$(STAGING_DIR)/usr/include")' \
		> $(PKG_BUILD_DIR)/cmake_fake/nlohmann_jsonConfig.cmake

	printf '%s\n' \
		'set(httplib_FOUND TRUE CACHE BOOL "" FORCE)' \
		'add_library(httplib::httplib INTERFACE IMPORTED)' \
		'set_target_properties(httplib::httplib PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "$(STAGING_DIR)/usr/include")' \
		> $(PKG_BUILD_DIR)/cmake_fake/httplibConfig.cmake

	mkdir -p $(PKG_BUILD_DIR)/fmt_shim/fmt
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/args.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/args.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/chrono.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/chrono.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/color.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/color.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/compile.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/compile.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/core.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/core.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/format.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/format.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/format-inl.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/format-inl.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/locale.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/locale.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/os.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/os.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/ostream.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/ostream.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/printf.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/printf.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/ranges.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/ranges.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/std.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/std.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/time.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/time.h
	printf '%s\n' \
		'#include <spdlog/fmt/bundled/xchar.h>' \
		> $(PKG_BUILD_DIR)/fmt_shim/fmt/xchar.h

	printf '%s\n' \
		'set(fmt_FOUND TRUE CACHE BOOL "" FORCE)' \
		'add_library(fmt::fmt INTERFACE IMPORTED)' \
		'set_target_properties(fmt::fmt PROPERTIES' \
		'  INTERFACE_INCLUDE_DIRECTORIES "$(PKG_BUILD_DIR)/fmt_shim"' \
		'  INTERFACE_COMPILE_DEFINITIONS "FMT_HEADER_ONLY")' \
		'set(fmt_INCLUDE_DIRS "$(PKG_BUILD_DIR)/fmt_shim")' \
		> $(PKG_BUILD_DIR)/cmake_fake/fmtConfig.cmake

	printf '%s\n' \
		'set(spdlog_FOUND TRUE CACHE BOOL "" FORCE)' \
		'add_library(spdlog::spdlog INTERFACE IMPORTED)' \
		'set_target_properties(spdlog::spdlog PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "$(STAGING_DIR)/usr/include")' \
		> $(PKG_BUILD_DIR)/cmake_fake/spdlogConfig.cmake

	printf '%s\n' \
		'add_library(libidn2::libidn2 SHARED IMPORTED)' \
		'set_target_properties(libidn2::libidn2 PROPERTIES' \
		'  IMPORTED_LOCATION "$(STAGING_DIR)/usr/lib/libidn2.so"' \
		'  INTERFACE_INCLUDE_DIRECTORIES "$(STAGING_DIR)/usr/include")' \
		'set(libidn2_FOUND TRUE CACHE BOOL "" FORCE)' \
		> $(PKG_BUILD_DIR)/cmake_fake/libidn2Config.cmake

	printf '%s\n' \
		'add_library(brotli::brotlicommon SHARED IMPORTED)' \
		'set_target_properties(brotli::brotlicommon PROPERTIES' \
		'  IMPORTED_LOCATION "$(STAGING_DIR)/usr/lib/libbrotlicommon.so"' \
		'  INTERFACE_INCLUDE_DIRECTORIES "$(STAGING_DIR)/usr/include")' \
		'add_library(brotli::brotlidec SHARED IMPORTED)' \
		'set_target_properties(brotli::brotlidec PROPERTIES' \
		'  IMPORTED_LOCATION "$(STAGING_DIR)/usr/lib/libbrotlidec.so"' \
		'  INTERFACE_INCLUDE_DIRECTORIES "$(STAGING_DIR)/usr/include")' \
		'add_library(brotli::brotlienc SHARED IMPORTED)' \
		'set_target_properties(brotli::brotlienc PROPERTIES' \
		'  IMPORTED_LOCATION "$(STAGING_DIR)/usr/lib/libbrotlienc.so"' \
		'  INTERFACE_INCLUDE_DIRECTORIES "$(STAGING_DIR)/usr/include")' \
		'set(brotli_FOUND TRUE CACHE BOOL "" FORCE)' \
		> $(PKG_BUILD_DIR)/cmake_fake/brotliConfig.cmake

	printf '%s\n' \
		'set(jwt-cpp_FOUND TRUE CACHE BOOL "" FORCE)' \
		'add_library(jwt-cpp::jwt-cpp INTERFACE IMPORTED)' \
		'set_target_properties(jwt-cpp::jwt-cpp PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "$(STAGING_DIR)/usr/include")' \
		> $(PKG_BUILD_DIR)/cmake_fake/jwt-cppConfig.cmake

	printf '%s\n' \
		'set(prometheus-cpp_FOUND TRUE CACHE BOOL "" FORCE)' \
		'add_library(prometheus-cpp::core INTERFACE IMPORTED)' \
		'set_target_properties(prometheus-cpp::core PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "$(STAGING_DIR)/usr/include")' \
		> $(PKG_BUILD_DIR)/cmake_fake/prometheus-cppConfig.cmake

	printf '%s\n' \
		'add_executable(yaff::protoc_plugin IMPORTED)' \
		'set_property(TARGET yaff::protoc_plugin PROPERTY IMPORTED_LOCATION "$(YAFF_HOST_PLUGIN)")' \
		'add_library(yaff::core INTERFACE IMPORTED)' \
		'set_target_properties(yaff::core PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "$(STAGING_DIR)/usr/include")' \
		'add_library(yaff::proto STATIC IMPORTED)' \
		'set_target_properties(yaff::proto PROPERTIES IMPORTED_LOCATION "$(YAFF_LIB_DIR)/libyaff_proto.a" INTERFACE_INCLUDE_DIRECTORIES "$(STAGING_DIR)/usr/include")' \
		'include("$(YAFF_GENERATE_MODULE)")' \
		> $(PKG_BUILD_DIR)/cmake_fake/YaFFConfig.cmake

	$(call Package/fptn-client/fptn_sanitizers_strip)

	$(Build/Configure/Default)
endef

define Build/Compile
	if [ -f $(PKG_BUILD_DIR)/_deps/camouflagetls-src/src/builder.cpp ]; then \
		sed -i '1i #include <algorithm>' $(PKG_BUILD_DIR)/_deps/camouflagetls-src/src/builder.cpp; \
	fi

	$(call Package/fptn-client/fptn_sanitizers_strip)

	$(STAGING_DIR_HOST)/bin/ninja -C $(PKG_BUILD_DIR) fptn-client-cli fptn-tcp-probe
endef

define Build/Install
	:
endef

FPTN_DEPLOY_FILES:=$(PKG_BUILD_DIR)/deploy/openwrt/data/files/etc

define Package/fptn-client/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/fptn-client/fptn-client-cli $(1)/usr/bin/fptn-client-cli
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/deploy/openwrt/fptn-tcp-probe/fptn-tcp-probe $(1)/usr/bin/fptn-tcp-probe

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(FPTN_DEPLOY_FILES)/init.d/fptn $(1)/etc/init.d/fptn

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(FPTN_DEPLOY_FILES)/uci-defaults/99-fptn $(1)/etc/uci-defaults/99-fptn

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(FPTN_DEPLOY_FILES)/config/fptn $(1)/etc/config/fptn

	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DATA) $(STAGING_DIR)/usr/lib/libre2.so.11.0.0 $(1)/usr/lib/libre2.so.11
	$(INSTALL_DATA) $(STAGING_DIR)/usr/lib/libprotobuf.so.29.5.0 $(1)/usr/lib/libprotobuf.so.29.5.0
	$(INSTALL_DATA) $(STAGING_DIR)/usr/lib/libutf8_validity.so $(1)/usr/lib/libutf8_validity.so
endef

define Package/fptn-client/conffiles
/etc/config/fptn
endef

$(eval $(call BuildPackage,fptn-client))
