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
	_plog=/tmp/fptn-pkg.log
	if have opkg; then
		{ opkg update && opkg install "$1"; } >"$_plog" 2>&1 && return 0
	elif have apk; then
		{ apk update && apk add "$1"; } >"$_plog" 2>&1 && return 0
	else
		return 1
	fi
	warn "не удалось установить пакет '$1':"
	tail -n 5 "$_plog" 2>/dev/null | sed 's/^/  /' >&2
	return 1
}

# интерактивный вопрос в ssh-tty; без tty или при FPTN_YES=1 отвечает сам
ask() {
	[ -n "${FPTN_YES:-}" ] && return 0
	r=""
	# при `wget ... | sh` stdin — труба, поэтому спрашиваем через /dev/tty
	if { : < /dev/tty; } 2>/dev/null; then
		printf '%s [y/N] ' "$*" >&2
		read -r r </dev/tty 2>/dev/null
	fi
	case "$r" in
		y|Y|yes|Yes|YES|д|Д|да|Да) return 0 ;;
		*) return 1 ;;
	esac
}

dl() {
	if have wget; then
		wget -q -O "$2" "$1" || return 1
		[ -s "$2" ] || return 1
		return 0
	fi
	if have curl; then
		curl -fsSL -o "$2" "$1" || return 1
		[ -s "$2" ] || return 1
		return 0
	fi
	warn "не установлены ни wget, ни curl"
	if ask "1) Установить wget и качать им"; then
		install_pkg wget || die "не удалось установить wget (откройте доступ к репозиториям пакетов)"
		wget -q -O "$2" "$1" || return 1
		[ -s "$2" ] || return 1
		return 0
	fi
	if ask "2) Установить curl и качать им"; then
		install_pkg curl || die "не удалось установить curl (откройте доступ к репозиториям пакетов)"
		curl -fsSL -o "$2" "$1" || return 1
		[ -s "$2" ] || return 1
		return 0
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
	# 1) GitHub API (может быть rate-limited)
	if dl "https://api.github.com/repos/$REPO/releases/latest" "$m/meta"; then
		VERSION=$(sed -n 's/^[[:space:]]*"tag_name":[[:space:]]*"v\?\([^"]*\)".*/\1/p' "$m/meta" | head -n1)
	fi
	# 2) atom-лента релизов (github.com; лимитов API нет)
	if [ -z "$VERSION" ] && dl "https://github.com/$REPO/releases.atom" "$m/atom"; then
		VERSION=$(sed -n 's/.*<title>\(v[0-9][^<]*\)<\/title>.*/\1/p' "$m/atom" | head -n1)
	fi
	# 3) файл version в репозитории (redirect на sha обходит кэш ветки raw.githubusercontent.com)
	if [ -z "$VERSION" ] && dl "https://github.com/$REPO/raw/main/version" "$m/ver"; then
		VERSION=$(tr -d '[:space:]' < "$m/ver")
	fi
	# 4) тот же файл напрямую с raw.githubusercontent.com
	if [ -z "$VERSION" ] && dl "https://raw.githubusercontent.com/$REPO/main/version" "$m/ver"; then
		VERSION=$(tr -d '[:space:]' < "$m/ver")
	fi
	rm -rf "$m"
	VERSION="${VERSION#v}"
	# версия обязана быть числами и точками (тела 404/HTML отсеиваем)
	case "$VERSION" in
		''|*[!0-9.]*) VERSION="" ;;
	esac
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
	if have unzip; then
		( cd "$TD" && unzip -oq "$1" ) 2>/dev/null && return 0
	fi
	if have busybox && busybox unzip --help >/dev/null 2>&1; then
		( cd "$TD" && busybox unzip -oq "$1" ) 2>/dev/null && return 0
	fi
	if have python3; then
		( cd "$TD" && python3 -c 'import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(".")' "$1" ) 2>/dev/null && return 0
	fi
	# unzip отсутствует — ставим пакет (обязательная зависимость для распаковки zip)
	log "unzip не найден, устанавливаю пакет unzip..."
	install_pkg unzip || die "не удалось установить unzip: поставьте вручную ('apk update && apk add unzip' или 'opkg update && opkg install unzip') и повторите"
	( cd "$TD" && unzip -oq "$1" ) 2>/dev/null \
		|| ( cd "$TD" && busybox unzip -oq "$1" ) 2>/dev/null \
		|| die "unzip установлен, но распаковать не удалось"
	return 0
}
extract_zip "$ZIP"

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
# full и slim несовместимы (общие *.so, slim ещё и PROVIDES fptn-client).
# Снимаем несовместимый вариант и luci, иначе apk/opkg не сможет выбрать.
case "$(basename "$CLIENT")" in
	*-slim-*) OTHER=fptn-client ;;
	*)        OTHER=fptn-client-slim ;;
esac
if have apk; then
	apk del luci-app-fptn >/dev/null 2>&1
	apk del "$OTHER" >/dev/null 2>&1
elif have opkg; then
	opkg remove luci-app-fptn >/dev/null 2>&1
	opkg remove "$OTHER" >/dev/null 2>&1
fi
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