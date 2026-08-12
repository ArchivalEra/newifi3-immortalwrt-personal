# hdd-modules — 寄生模块集（刷机后装到硬盘，不烧 flash）

**架构原则（用户 2026-08-12 声明）**：flash 固件 = ImmortalWrt **出厂默认配置**（唯一改动 LAN 192.168.50.1/24）+ 极简包。
一切自定义（伪装 / 认证 / v6 / 硬件加速开关）都是**寄生模块**，本目录统一存放，装到硬盘（如 `/mnt/data/hdd-modules/` 或 extroot 的 `/etc/` 下）按需启用。
**摘除模块 = 回退出厂默认路由器，硬件加速不受任何限制。**

## 模块清单

| 模块 | 内容 | 默认 |
|---|---|---|
| `cloak/` | 伪装模块：TTL 统一 64 + 软分载保证 + WAN 固定 MAC（install/remove） | 需手动启用 |
| `portal/` | 校园网认证（H3C）：PortalAuthenticator(A/B/C) + AuthenticatorTriggers(a/b/c) + init.d（install/remove） | 需手动启用 |
| `accel/` | 硬件加速开关（hw-on / hw-off，可选增强档；与 cloak 互斥） | 出厂默认（hw 关） |
| `wan6/` | IPv6 三形态（OFF / A 双栈 / B 仅 WAN）—— 到校实测公网 v6 后启用 | OFF |

## 用法

```
# 刷机 + ext4 挂载后（extroot 的 /etc/ 或 /mnt/data/ 均可）
scp -r hdd-modules/ root@192.168.50.1:/mnt/data/
ssh root@192.168.50.1
/mnt/data/hdd-modules/cloak/install.sh     # 启用伪装
/mnt/data/hdd-modules/portal/install.sh    # 部署认证（再编辑 /etc/portal.conf 填凭据）
# ... 摘除回退：
/mnt/data/hdd-modules/cloak/remove.sh
/mnt/data/hdd-modules/portal/remove.sh
```

## Fallback 保证

任一模块 `remove.sh` 后，对应配置（nft 规则 / firewall / network / init.d）全部还原为出厂默认。
恢复出厂基线：`firstboot`（清空 overlay）回到纯出厂镜像。
