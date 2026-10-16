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
  by the init script are identical to upstream. Our `luci-app-fptn` is the stock
  one plus a small patch (`patches/`) for the split-tunnel list.
* Runtime deps: only `kmod-tun` and `ip-full` — no `libstdcpp`/boost/protobuf.

## Split tunnel

`enable_split_tunnel`, `split_tunnel_mode` and the rest of the UCI schema match
upstream. The domain list, however, is stored in a **plain text file**:

```
/etc/fptn/split-tunnel-domains.txt   # one domain per line; empty = built-in list
```

The init script passes `--split-tunnel-domains-file` only when that file is
non-empty; otherwise the client falls back to the built-in list embedded in the
binary (`data/split-tunnel-domains.txt`, upstream `deploy/domain_blacklist/russia.txt`).
LuCI manages the file with Import / Export / Delete buttons, and
`fptn-client-rs --print-split-tunnel-domains` dumps the built-in list without
root.

## Connection pool

`enable_pool` (default `0`) turns on the client's connection-pool strategies —
`dual-rolling-tunnel`, `triple-rolling-tunnel` and `browser-mimicry`. It is
deliberately **off** on the router: a pool keeps several tunnels open at once,
which costs RAM, so it must be enabled explicitly. With the pool disabled the
client logs a warning and falls back to a single `rolling-tunnel`. The
`connection_strategy` option selects the strategy used when the pool is enabled.
See the main project README for the strategy semantics.

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
