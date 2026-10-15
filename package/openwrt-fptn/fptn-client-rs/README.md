# fptn-client-rs (OpenWrt package)

OpenWrt packaging for the Rust port of the FPTN client. It ships a **prebuilt**
static-musl binary instead of building Rust in the buildroot (see the comment in
the `Makefile` for why).

## Layout

| Path | Purpose |
|------|---------|
| `Makefile` | Package definition (`fptn-client-rs`). |
| `files/fptn.init` | procd init script, installed as `/etc/init.d/fptn`. |
| `files/fptn.config` | UCI config, installed as `/etc/config/fptn`. |
| `files/99-fptn` | uci-defaults: adds the `fptn` firewall zone. |
| `files/fptn-client-rs`, `files/fptn-tcp-probe` | **Staged binaries** (git-ignored). |

## Compatibility

* `PROVIDES:=fptn-client` — satisfies `luci-app-fptn`'s `+fptn-client` dependency.
* `CONFLICTS:=fptn-client fptn-client-slim` — the C++ clients own the same
  `/etc/init.d/fptn` and `/etc/config/fptn`.
* UCI schema (`/etc/config/fptn`), procd service name (`fptn`) and the CLI used
  by the init script are identical to upstream, so the stock `luci-app-fptn`
  works unchanged.
* Runtime deps: only `kmod-tun` and `ip-full` — no `libstdcpp`/boost/protobuf.

## Staging the binaries

From the `fptn-client-rs` repo:

```sh
scripts/stage-openwrt.sh                      # defaults to ../openwrt-fptn/package/openwrt-fptn/fptn-client-rs
scripts/stage-openwrt.sh /path/to/this/dir    # or an explicit package directory
```

This cross-builds `fptn-client-rs` and `fptn-tcp-probe` (zigbuild,
`mipsel-unknown-linux-musl`) and copies them into `files/`.

## Building

```sh
# in an OpenWrt tree with this repo overlaid as a feed
make package/openwrt-fptn/fptn-client-rs/compile V=sc
```
