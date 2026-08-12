---
title: 加速与伪装如何兼得
type: grilling
label: wayfinder:grilling
status: closed
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

grilling 于 2026-08-12 完成。决策依据：newifi3 仅承担**有线主干**（无线 WLAN 流量分流给华为 AX3 等设备），负载有限 → 加速感知增益趋近于零，伪装完整性优先，不赌 hw offload 稳定性。

**默认档 = 伪装完整档**（单选默认）：
- `flow_offloading 1`（软分载，25.12 默认开启）+ `fullcone 1`
- nft `ip ttl set 64`：Lan→Wan forward 链逐包 TTL 修正（软分载不绕 netfilter，完整生效）
- WAN 固定 MAC + 单 IP NAT（全子网 MASQUERADE 成一个出口）+ 关 IPv6 + UA 正常（真实浏览器 UA）

**hw offload 降级为可选增强档**：配置双份 + 一键切换脚本（改 firewall 配置 + 重载 nftables）；切换后 TTL 逐包修正失效（身份伪装保留），已知风险 openwrt#24459（watchdog 重启）/ #10354 / #7279 记录在案，默认不启用。

用户 2026-08-12 确认：**"硬件加速仍然要，只是作为选项"** —— 加速选项不删除，保留为可选档（默认关、可一键开）。

**SFE 排除**：官方 25.12.1 不存在（票 1 已核实），彻底出局。

**伪装清单最终定版**：
- ① 单 IP NAT ② WAN 固定 MAC ③ 关 IPv6 ④ UA 正常 ⑤ TTL 统一 64（软分载档生效）—— **全部采纳**
- ⑥ TCP 时间戳/窗口缩放等次要指纹 —— **先不做**，实机验证后按需追加

**实机必测项（写入票 4 规格）**：刷机后验证 WAN 侧实际发包 TTL 一致性（不同初始 TTL 的设备 NAT 后是否统一为 64，需一台检测设备抓 WAN 侧包）。

**网络拓扑注记**：newifi3 仅有线主干；无线分流华为 AX3（WiFi6 3000M，AP 桥接）；S905 一体机属另一项目。
