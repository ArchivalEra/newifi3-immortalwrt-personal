---
title: 加速与伪装如何兼得
type: grilling
label: wayfinder:grilling
status: open
blocked-by: [01-immortalwrt-25-12-1-facts.md]
blocks: [04-firmware-spec.md]
parent: ../map.md
---

## Question

"硬件加速的所有相关选项全开"与"所有子网设备伪装为一个（TTL 统一等）"最终如何组合？

已知事实（票 1 已核实，2026-08-12）：PPE 硬分载/SFE/软分载与逐包 TTL 改写互斥（硬分载绕开 netfilter）。**SFE 在官方 25.12.1 不存在（已排除）**。TTL 统一用 nft `ip ttl set 64`（1.1.6 确认可用）。mtk_ppe hw offload 可用但有已知坑（openwrt#24459 watchdog 重启等）。25.12 默认 `flow_offloading 1`（软分载开）+ fullcone。

需裁决：
- 默认档位与切换形态（单选默认 vs 运行时切换 vs 配置双份）
- ~~SFE 与 PPE 硬分载的同跑裁决~~（SFE 不存在，已排除）→ 软分载 vs 硬分载（PPE）取舍：接受已知稳定性风险全开硬分载 vs 默认软分载、hardware offload 作为可切换增强
- 伪装手段的最终清单（TTL 统一/时间戳清除/MAC/UA/窗口等）
- 若默认加速：伪装靠什么兜底（单 IP + 单 MAC + 关 v6）

## Resolution

（grilling 对话完成时记录）
