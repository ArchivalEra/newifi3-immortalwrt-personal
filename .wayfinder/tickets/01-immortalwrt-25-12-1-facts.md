---
title: ImmortalWrt 25.12.1 事实核查
type: research
label: wayfinder:research
status: closed
blocked-by: []
blocks: [02-accel-vs-cloak.md]
parent: ../map.md
---

## Question

ImmortalWrt 25.12.1（Stable, 2026-07-06）在 ramips/mt7621 目标上的构建与加速事实：

1. 该版本是否发布 ramips/mt7621 的 Image Builder？精确下载 URL（官方 + 清华镜像）与 make image 用法（PROFILE=d-team_newifi-d2）
2. mtk_ppe 硬件分载在该版本内核（6.12 系？）中的状态：是否随内核启用、fw4 flowtable `hw_offload` 是否可用、已知问题
3. kmod-sfe / kmod-nft-sfe 是否在该版本软件源中（ramips/mt7621）
4. nftables 是否支持 `ip ttl set 64`；xt_TCPOPTSTRIP 的 kmod 包名是否存在
5. breed 刷该版本 sysupgrade.bin 的注意点（newifi-d2）

结论落到 `newifi3/.wayfinder/research/01-immortalwrt-facts.md`，正文只留要点+URL。

## Resolution

研究于 2026-08-12 完成，全文见 `research/01-immortalwrt-facts.md`。要点：

1. **IB 存在**：`immortalwrt-imagebuilder-25.12.1-ramips-mt7621.Linux-x86_64.tar.zst`（**zst 压缩**）。官方源 + 清华镜像均慢/不可用（TUNA 404 不镜像 ImmortalWrt），实际用 **SJTU 镜像**（已验证 200）下载成功。命令 `make image PROFILE=d-team_newifi-d2 PACKAGES="..." FILES=<dir>`；产物 squashfs-sysupgrade.bin，IMAGE_SIZE 上限 32448k。
2. **mtk_ppe hw offload 可用但有已知坑**：`CONFIG_NET_MEDIATEK_SOC=y` 编译 PPE（6.12 无独立开关），mt7621_data 置 `ppe_num=1, offload_version=1`；fw4 `flow_offloading_hw '1'` 生成 `flags offload` flowtable，不可用自动回退软分载。**已知问题**：openwrt#24459（hw 卸载 + tcpdump 触发 watchdog 重启，25.12.5 复现）、#10354（只暂时工作）、#7279（崩溃）。软件卸载（`flow_offloading 1`）默认开启，稳妥。
3. **SFE 完全不存在**：官方二进制 feed 与 immortalwrt/packages 源码（net/）均无 kmod-sfe/kmod-nft-sfe。要 SFE 只能自编第三方 feed → **票 2 排除 SFE 路径**。
4. **`ip ttl set 64` 可用**（nftables 1.1.6，内核 nft_payload 网络头可写，proto.c 有 ttl/hoplimit 模板）；**xt_TCPOPTSTRIP 不存在**（netfilter.mk 与 mt7621 config 均无）→ 统一 TTL 用 nft 即可，勿用 TCPOPTSTRIP。iptables TTL 由 kmod-ipt-ipopt 提供。
5. **breed 刷机**：`breed-mt7621-newifi-d2.bin` 官方可用；OpenWrt 布局 bootloader 分区名 `u-boot`（0x0-0x30000）；**breed 默认关 USB 供电，必须设环境变量 `newifi-d2.usb_pwr_en=1`**（否则 1T 硬盘 USB 无电）；复位键 GPIO#3；breed Web 192.168.1.1 直接刷 sysupgrade.bin。

对票 2/4 的影响：SFE 出局；TTL 伪装走 nft 软分载路径；hw offload 需用户对稳定性拍板（默认软分载 vs 冒险硬分载）。
