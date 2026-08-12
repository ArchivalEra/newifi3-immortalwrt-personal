# accel — 硬件加速开关模块（可选增强档）

票 2 决策：硬件加速保留为**可选档**（用户确认"硬件加速仍然要，只是作为选项"）。
本模块提供一键开关，**默认不启用**（出厂 firewall 即默认态，装不装本模块都不影响系统默认）。

## 用法

```
hdd-modules/accel/hw-on.sh    # 开启 PPE 硬件流卸载（flow_offloading_hw=1）
hdd-modules/accel/hw-off.sh   # 关闭（回软分载，默认态）
```

## 注意

- **与 cloak 模块互斥**：hw offload 生效时 netfilter 被绕开 → TTL 逐包修正失效（身份伪装仍在）。
  顺序建议：先 cloak/remove.sh 或接受 TTL 修正失效，再 hw-on。
- 已知风险（票 1 研究记录）：openwrt#24459（watchdog 重启）、#10354（只暂时工作）、#7279（崩溃）。
  出问题就 hw-off.sh 回退。
- 切换后 `firewall restart` 会瞬断。
