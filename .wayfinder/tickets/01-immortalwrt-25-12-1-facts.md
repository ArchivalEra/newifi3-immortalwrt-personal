---
title: ImmortalWrt 25.12.1 事实核查
type: research
label: wayfinder:research
status: open
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

（由 research 子代理完成；关闭时在此记录结论摘要并更新 map 的 Decisions so far）
