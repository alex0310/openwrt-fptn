include $(TOPDIR)/rules.mk

PKG_NAME:=boringssl
PKG_VERSION:=0.20260813.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com
PKG_HASH:=37e23cb9a5fa54f01b07cadd653cebc1d1b235945439a6c334fea58ea47b5b0a
PKG_BUILD_DIR:=$(BUILD_DIR)/boringssl-$(PKG_VERSION)

PKG_MAINTAINER:=Vasek
PKG_LICENSE:=OpenSSL-ISC

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/boringssl
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=BoringSSL - Google OpenSSL fork
  URL:=https://googlesource.com
  DEPENDS:=+libstdcpp +libpthread
  # Библиотека статическая, в прошивку не попадает и ничего не провайдит:
  # PROVIDES на libopenssl конфликтовал бы с настоящим OpenSSL из package/libs/openssl.
  HIDDEN:=1
endef

define Package/boringssl/description
  BoringSSL is a fork of OpenSSL that is designed to meet Google's needs.
endef

CMAKE_OPTIONS += \
	-DOPENSSL_NO_ASM=ON \
	-DENABLE_TESTS=OFF

define Build/InstallDev
	# BoringSSL ставится только как статическая библиотека для статической линковки
	# из build_dir (см. -l:libssl.a в package/utils/fptn). Кладём заголовочные файлы
	# в отдельный префикс, чтобы не перетирать libssl.so/libcrypto.so в $(STAGING_DIR)/usr/lib:
	# там лежат симлинки на версионированные библиотеки настоящего OpenSSL, и без версии
	# библиотека попадает в staging с SONAME=libssl.so, из-за чего CheckDependencies
	# падает на boost-cobalt и любых пакетах, линкующихся с libssl.
	$(INSTALL_DIR) $(1)/usr/include/boringssl
	$(CP) $(PKG_BUILD_DIR)/include/* $(1)/usr/include/boringssl/
endef

define Package/boringssl/install
	:
endef
define Build/Prepare
	$(call Build/Prepare/Default)

	# 1. Добавляем объявление ТОЛЬКО недостающей функции в инклюд ssl.h
	sed -i '/OPENSSL_EXPORT int SSL_set_tlsext_host_name/a \\n\/\/ Chromium TLS Stub for FPTN\nOPENSSL_EXPORT int SSL_set_tls_hello_custom_session_id(SSL *ssl, const uint8_t *session_id, size_t session_id_len);' $(PKG_BUILD_DIR)/include/openssl/ssl.h

	# 2. Оставляем только ОДНУ функцию подмены сессии (остальные уже встроены в ssl_lib.cc)
	printf '\nextern "C" {\nint SSL_set_tls_hello_custom_session_id(SSL *ssl, const uint8_t *session_id, size_t session_id_len) {\n  if (ssl == nullptr || session_id_len > 32) return 0;\n  SSL_SESSION *session = SSL_get_session(ssl);\n  if (session != nullptr) {\n    return SSL_SESSION_set1_id(session, session_id, session_id_len);\n  }\n  return 1;\n}\n}\n' >> $(PKG_BUILD_DIR)/ssl/handshake.cc
endef






$(eval $(call BuildPackage,boringssl))
