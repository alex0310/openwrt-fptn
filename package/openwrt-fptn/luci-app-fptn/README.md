# luci-app-fptn (OpenWrt package)

LuCI app for the FPTN client. It is built from the upstream tarball (pinned
commit) with one local patch.

## Layout

| Path | Purpose |
|------|---------|
| `Makefile` | Package definition; downloads the upstream LuCI sources. |
| `patches/001-split-tunnel-domains-file.patch` | Local changes to the upstream `main.js` + ACL. |

## The patch

Upstream stores the split-tunnel domain list in a UCI list
(`fptn.config.split_tunnel_domains`). We instead keep it in
`/etc/fptn/split-tunnel-domains.txt` so the client can read it directly
(`--split-tunnel-domains-file`) and fall back to the built-in list when it is
missing or empty.

The patch changes:

* **`main.js`** — replaces the two `split_tunnel_domains` textareas with a
  file-backed editor that has **Import**, **Export**, **Download from repo** and
  **Delete** buttons. The editor persists through the normal *Save & Apply*
  flow; an empty value removes the file (i.e. reverts to the built-in list), and
  *Export* dumps the built-in list via
  `fptn-client-rs --print-split-tunnel-domains`. *Download from repo* fetches a
  fresh list with the browser's `fetch()` and fills the textarea; it does not
  save by itself.
* **`acl.d/luci-app-fptn.json`** — grants the rpcd permissions the editor
  needs: `read`/`write` on `/etc/fptn/split-tunnel-domains.txt` and `exec` on
  `/usr/bin/fptn-client-rs`.

Patches are applied because the package overrides `Build/Prepare` (to unpack the
tarball); the override calls `$(Build/Patch)` explicitly, since the default
`Build/Prepare` is what normally applies `./patches`.

## Domain list mirror

The canonical list is `data/split-tunnel-domains.txt` in the client repo
(`alex0310/fptn-client-rs`), which is private. The LuCI page runs in the browser
and cannot authenticate to GitHub, so this (public) feed carries a copy at
`data/split-tunnel-domains.txt`; *Download from repo* loads it from

```
https://raw.githubusercontent.com/alex0310/openwrt-fptn/main/data/split-tunnel-domains.txt
```

Keep the copy in sync when the client's built-in list changes.

## Rebuilding the patch

`patches/*.patch` are `-p1` patches rooted at the stripped tarball
(`deploy/openwrt/...`), so they can be regenerated with a plain unified diff
against a fresh extraction of `luci-app-fptn-$(PKG_VERSION).tar.gz`.

## Building

```sh
# in an OpenWrt tree with this repo overlaid as a feed
make package/openwrt-fptn/luci-app-fptn/compile V=sc
```
