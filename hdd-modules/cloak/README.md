# cloak — 伪装模块（寄生模块，可摘除）

**用途**：把"所有 LAN 设备伪装为一个"的身份统一层。启用后生效，`remove.sh` 一键摘除，系统回退 ImmortalWrt 出厂默认（硬件加速不受限制）。

## 启用后做什么（install.sh）

1. **TTL 统一 64**：部署 `/etc/nftables.d/10-cloak.nft`，Lan→Wan 转发统一 IPv4 TTL=64（IPv6 hoplimit 视实机启用）
2. **保证软分载**：`flow_offloading=1` + `flow_offloading_hw=0`（TTL 逐包修正要求包过 netfilter；硬分载会绕开 → 不生效）
3. **WAN 固定 MAC**：`/etc/config/cloak` 配置固定 MAC（与出厂默认解耦，摘除即还原）
4. fullcone 保持默认开启（与伪装不冲突）

## 摘除后（remove.sh）

- 删除 nftables.d 规则 → firewall 恢复出厂（flow_offloading_hw 回默认，可自由开硬件加速）
- 还原 WAN MAC
- 系统回到"极好的路由器"默认态

## 与加速模块的关系

| 模块组合 | 效果 |
|---|---|
| cloak 开（默认） | TTL 修正完整生效（软分载） |
| cloak 开 + accel/hw-on | **互斥**：hw offload 生效则 TTL 修正失效（模块会警告） |
| cloak 摘除 + accel/hw-on | 出厂配置 + 硬件加速拉满（用户声明的 fallback 场景） |

## 实机验证点（写入验证清单）

- `nft list ruleset` 确认 ttl 规则在 forward 链且位于 flow offload **之前**（位置不对则 TTL 不生效）
- WAN 侧抓包：不同初始 TTL 设备（64/128）NAT 后统一 64
- `remove.sh` 后 firewall 配置与出厂一致
