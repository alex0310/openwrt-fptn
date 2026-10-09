#!/bin/sh
#
# FPTN — установщик для OpenWrt
#
# Использование:
#   sh install-fptn.sh [версия v0.4.5] [--slim|--full]
#
#   Версия по умолчанию — последний релиз (GitHub API).
#   Вариант по умолчанию — fptn-client-slim (доступна всегда), если не указан --full.
#   FPTN_YES=1 — не спрашивать, ставить недостающие wget/curl/unzip автоматически.
#
# Запуск с роутера:
#   curl -fsSL https://raw.githubusercontent.com/alex0310/openwrt-fptn/main/install-fptn.sh | sh
#   wget -qO- https://raw.githubusercontent.com/alex0310/openwrt-fptn/main/install-fptn.sh | sh
#

REPO="alex0310/openwrt-fptn"
VERSION=""
VARIANT=""

for a in "$@"; do
	case "$a" in
		--slim) VARIANT=slim ;;
		--full) VARIANT=full ;;
		v[0-9]*|[0-9]*) VERSION="${a#v}" ;;
	esac
done

log() { printf '%s\n' "$*"; }
die() { log "ОШИБКА: $*"; exit 1; }
warn() { log "WARNING: $*"; }

have() { command -v "$1" >/dev/null 2>&1 || which "$1" >/dev/null 2>&1; }

install_pkg() {
	if have opkg; then opkg update >/dev/null 2>&1 && opkg install "$1" >/dev/null 2>&1 && return 0
	elif have apk; then apk add "$1" >/dev/null 2>&1 && return 0
	fi
	return 1
}

# интерактивный вопрос в ssh-tty; без tty или при FPTN_YES=1 отвечает сам
ask() {
	[ -n "${FPTN_YES:-}" ] && return 0
	r=""
	if tty -s 2>/dev/null; then
		printf '%s [y/N] ' "$*" >&2
		read -r r </dev/tty 2>/dev/null
	fi
	case "$r" in
		y|Y|yes|Yes|YES|д|Д|да|Да) return 0 ;;
		*) return 1 ;;
	esac
}

dl() {
	if have wget; then wget -q -O "$2" "$1"; return 0; fi
	if have curl; then curl -fsSL -o "$2" "$1"; return 0; fi
	warn "не установлены ни wget, ни curl"
	if ask "1) Установить wget и качать им"; then
		install_pkg wget || die "не удалось установить wget (откройте доступ к репозиториям пакетов)"
		wget -q -O "$2" "$1" && return 0
		die "wget не смог скачать: $1"
	fi
	if ask "2) Установить curl и качать им"; then
		install_pkg curl || die "не удалось установить curl (откройте доступ к репозиториям пакетов)"
		curl -fsSL -o "$2" "$1" && return 0
		die "curl не смог скачать: $1"
	fi
	die "чем качать? установите wget/curl вручную или запустите с FPTN_YES=1"
}

file_bytes() {
	ls -ln "$1" 2>/dev/null | awk '{print $5}'
}

avail_kb() {
	df -k "$1" 2>/dev/null | awk 'NR==2{print $4}'
}

mem_available_kb() {
	awk '/^MemAvailable:/{print $2; exit} /^MemFree:/{print $2; exit}' /proc/meminfo 2>/dev/null
}

# --- архитектура пакетов OpenWrt ---
get_arch() {
	if [ -f /etc/apk/arch ]; then
		cat /etc/apk/arch
		return
	fi
	if have opkg; then
		opkg print-architecture 2>/dev/null | sed -n 's/^arch \([^ ]*\) .*/\1/p' | head -n1
		return
	fi
	die "не удалось определить архитектуру: нет /etc/apk/arch и нет opkg"
}

# --- версия ---
if [ -z "$VERSION" ]; then
	m=$(mktemp -d /tmp/fptn.XXXXXX) || die "нет места в /tmp"
	dl "https://api.github.com/repos/$REPO/releases/latest" "$m/meta" \
		|| die "не удалось узнать последний релиз (укажите версию аргументом)"
	VERSION=$(sed -n 's/^[[:space:]]*"tag_name":[[:space:]]*"v\?\([^"]*\)".*/\1/p' "$m/meta" | head -n1)
	rm -rf "$m"
	[ -n "$VERSION" ] || die "не удалось определить последнюю версию"
fi

ARCH=$(get_arch)
[ -n "$ARCH" ] && [ "$ARCH" != "unknown" ] || die "не удалось определить архитектуру пакетов"
log "FPTN installer: version=$VERSION arch=$ARCH"

# --- скачивание zip нужной архитектуры ---
URLBASE="https://github.com/$REPO/releases/download/v$VERSION"
ZIP="/tmp/fptn-${VERSION}-${ARCH}.zip"
log "Скачиваю $URLBASE/fptn-${VERSION}-${ARCH}.zip"
dl "$URLBASE/fptn-${VERSION}-${ARCH}.zip" "$ZIP" \
	|| die "не удалось скачать zip (такая версия/архитектура есть в релизе? вручную: $URLBASE/fptn-${VERSION}-${ARCH}.zip)"

TD=$(mktemp -d /tmp/fptn.XXXXXX 2>/dev/null || { TD_FAIL=1; echo /tmp/fptn-install; })
[ "${TD_FAIL:-0}" = 1 ] && mkdir -p "$TD"
cleanup() { rm -rf "$TD" "$ZIP"; }
trap 'cleanup' EXIT HUP INT TERM

# --- распаковка ---
extract_zip() {
	( cd "$TD" && unzip -oq "$1" ) 2>/dev/null && return 0
	( cd "$TD" && busybox unzip -oq "$1" ) 2>/dev/null && return 0
	if have unzip; then
		( cd "$TD" && unzip -oq "$1" ) && return 0
	fi
	if ask "Установить unzip для распаковки"; then
		install_pkg unzip || die "не удалось установить unzip (откройте доступ к репозиториям пакетов)"
	fi
	( cd "$TD" && unzip -oq "$1" ) 2>/dev/null || return 1
	return 0
}
extract_zip "$ZIP" || die "не удалось распаковать zip: нет unzip (busybox unzip/пакет?)"

# --- выбор apk ---
SLIM=""
FULL=""
for f in "$TD"/fptn-client*.apk "$TD"/luci-app-fptn*.apk; do
	[ -e "$f" ] || continue
	case "$(basename "$f")" in
		*-slim-*) SLIM=$f ;;
		fptn-client-*) FULL=$f ;;
		luci-app-fptn-*) LUCI=$f ;;
	esac
done

case "$VARIANT" in
	full) CLIENT=$FULL ;;
	slim) CLIENT=$SLIM ;;
	*)
		CLIENT=${SLIM:-$FULL}
		[ -z "$FULL" ] && [ -z "$SLIM" ] && die "в zip нет fptn-client*.apk"
esac
CLIENT=${CLIENT:-$FULL}
[ -n "$CLIENT" ] || die "не выбран клиентский apk"
LUCI=${LUCI:-}

inst_bytes() {
	n=$(basename "$1")
	s=0
	if [ -f "$TD/sizes.txt" ]; then
		res=$(while read -r name bytes; do
			[ "$name" = "$n" ] && { echo "$bytes"; break; }
		done < "$TD/sizes.txt")
		[ -n "$res" ] && { echo "$res"; return; }
	fi
	# запасной вариант: поджатый размер x3 (приблизительные unpacked bytes)
	b=$(file_bytes "$1"); b=${b:-0}
	echo $(( b * 3 ))
}

# --- проверка места и памяти (только предупреждения) ---
CLIENT_NEEDED=$(inst_bytes "$CLIENT")
LUCI_NEEDED=0
[ -n "$LUCI" ] && LUCI_NEEDED=$(inst_bytes "$LUCI")
FLASH_NEEDED=$((CLIENT_NEEDED + LUCI_NEEDED))

FREE_ROOT_KB=$(avail_kb /); FREE_ROOT_KB=${FREE_ROOT_KB:-0}
FREE_TMP_KB=$(avail_kb /tmp); FREE_TMP_KB=${FREE_TMP_KB:-0}
MEM_KB=$(mem_available_kb); MEM_KB=${MEM_KB:-0}
FREE_ROOT=$((FREE_ROOT_KB * 1024))
FREE_TMP=$((FREE_TMP_KB * 1024))

ZIP_BYTES=$(file_bytes "$ZIP")
CLIENT_APK=$(file_bytes "$CLIENT")
LUCI_APK=0
[ -n "$LUCI" ] && LUCI_APK=$(file_bytes "$LUCI")
TMP_NEEDED=$((ZIP_BYTES + CLIENT_APK + LUCI_APK + 8 * 1024 * 1024))

hsize() { echo "$(( $1 / 1024 / 1024 )) МБ"; }

if [ "$FREE_ROOT" -lt "$FLASH_NEEDED" ]; then
	warn "мало свободного места на /: свободно $(hsize $FREE_ROOT), нужно около $(hsize $FLASH_NEEDED)"
fi
if [ "$FREE_TMP" -lt "$TMP_NEEDED" ]; then
	warn "мало места в /tmp (нужно для распаковки): свободно $(hsize $FREE_TMP), нужно около $(hsize $TMP_NEEDED)"
fi
if [ -n "$MEM_KB" ] && [ "$((MEM_KB * 1024))" -lt "$TMP_NEEDED" ]; then
	warn "мало оперативной памяти ($(hsize $((MEM_KB*1024)))): /tmp лежит в RAM, распаковка может не влезть"
fi

log "Устанавливаю: $CLIENT ${LUCI:-}"
if have apk; then
	apk add --allow-untrusted "$CLIENT" $LUCI
elif have opkg; then
	opkg install "$CLIENT" $LUCI
else
	die "нет ни apk, ни opkg"
fi

log "Установлено. Дальше:"
log "  /etc/init.d/fptn enable && /etc/init.d/fptn start"
log "  uci set fptn.client.server=SERVER_IP; uci commit fptn"
log "ZIP и временные файлы удалены автоматически."