include $(TOPDIR)/rules.mk

PKG_NAME:=protobuf29
PKG_VERSION:=29.5
PKG_RELEASE:=1

PKG_SOURCE:=protobuf-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com?
PKG_HASH:=a191d2afdd75997ba59f62019425016703daed356a9d92f7425f4741439ae544

# Задаем имена ваших скачанных архивов Abseil и GTest
ABSL_SOURCE:=abseil-cpp-20240722.0.tar.gz
GTEST_SOURCE:=googletest-1.15.2.tar.gz

PKG_MAINTAINER:=Vasek
PKG_LICENSE:=BSD-3-Clause

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/cmake.mk

# Направляем сборщик в правильную корневую папку Protobuf
HOST_BUILD_DIR:=$(BUILD_DIR_HOST)/protobuf-$(PKG_VERSION)

# ЧЕСТНАЯ И ПОЛНАЯ СБОРКА: Включаем все тесты, конформансы и экспорт для Protobuf и Abseil
HOST_CMAKE_OPTIONS += \
	-Dprotobuf_BUILD_TESTS=ON \
	-Dprotobuf_BUILD_CONFORMANCE=ON \
	-Dprotobuf_BUILD_EXPORT=ON \
	-Dprotobuf_ABSL_PROVIDER=module \
	-Dprotobuf_WITH_ZLIB=OFF \
	-DABSL_BUILD_TESTING=ON \
	-DABSL_USE_EXTERNAL_GOOGLETEST=OFF \
	-DABSL_FIND_GOOGLETEST=OFF \
	-DABSL_ENABLE_INSTALL=ON

define Host/Prepare
	$(Host/Prepare/Default)

	# 1. Распаковка оригинального чистого архива Abseil внутрь тулчейна
	mkdir -p $(HOST_BUILD_DIR)/third_party/abseil-cpp
	tar -C $(HOST_BUILD_DIR)/third_party/abseil-cpp --strip-components=1 -xzf $(DL_DIR)/$(ABSL_SOURCE)

	# 2. Честная распаковка Google Test для хоста
	mkdir -p $(HOST_BUILD_DIR)/third_party/googletest
	tar -C $(HOST_BUILD_DIR)/third_party/googletest --strip-components=1 -xzf $(DL_DIR)/$(GTEST_SOURCE)

	# 3. СИМЛИНК ДЛЯ МАРКЕРА CONFIGURATION
	ln -s protobuf-$(PKG_VERSION) $(BUILD_DIR_HOST)/protobuf29-$(PKG_VERSION) 2>/dev/null || true
endef

define Package/protobuf29
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Google Protocol Buffers v29 (Host compiler only)
  URL:=https://github.com
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,protobuf29))
