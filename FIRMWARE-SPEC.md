# Newifi3 校园网伪装网关固件 — 规格锁定 (FIRMWARE-SPEC)

> 状态：**规格锁定**（wayfinder 4 票全闭 + 架构原则修订，2026-08-12）
> 底座：ImmortalWrt 25.12.1 Stable（2026-07-06，apk 包格式，kernel 6.12.94）
> 构建：Image Builder 离线（repositories 已补丁 file://），免编译

---

## 0. 架构原则（用户 2026-08-12 声明，最高优先级）

> **flash 固件 = ImmortalWrt 出厂默认配置（唯一改动 LAN 192.168.50.1/24）+ 极简包**。
> 一切自定义（伪装 / 认证 / v6 / 硬件加速开关）都是**寄生模块**（`hdd-modules/`，装到硬盘），按需启用。
> **摘除模块 = 回退出厂默认路由器，硬件加速不受任何限制**。
> fallback 永远是系统默认配置；我们的功能只是寄生。

模块清单：`cloak/`（伪装：TTL+软分载+固定MAC，install/remove）、`portal/`（H3C 认证 A/B/C + 触发器 a/b/c）、`accel/`（hw offload 开关，可选增强档）、`wan6/`（IPv6 三形态，默认 OFF）。
每个模块 `remove.sh` 干净摘除；`firstboot` 恢复纯出厂。

## 1. 核心决策摘要

| 维度 | 决策 |
|---|---|
| 角色 | 纯有线主干网关；无线分流华为 AX3（WiFi6 AP 桥接）；S905 一体机属另一项目 |
| flash 默认 | ImmortalWrt 出厂配置 + LAN 192.168.50.1/24（唯一改动）；硬件加速出厂态（soft on / hw 关，可自由开） |
| 伪装（cloak 模块） | TTL 统一 64（nft，软分载路径）+ WAN 固定 MAC + 单 IP NAT + UA 正常；IPv6 默认关（wan6 模块） |
| 加速（accel 模块） | `flow_offloading_hw 1` 一键开关（可选增强档，默认关；规避 openwrt#24459 watchdog 风险）；与 cloak 互斥；SFE 官方不存在，排除 |
| Portal（portal 模块） | 学校网关为 **H3C**；认证器 A 通用表单 / B 录制重放 / C H3C 模板 + 触发器 a 常驻保活 5min / b 慵懒 / c 手动；配置驱动不重编译；HTTPS 优先，不自创加密 |
| 存储 | 1T HDD USB3：ext4 40G（extroot overlay）+ swap 10G（swappiness=5）+ XFS 剩余 → /mnt/data |
| flash 包 | 纯 SSH（dropbear）+ curl + 挂盘引导；LuCI 之后 `apk add` 到 ext4 |
| WiFi | 驱动全部保留，radio 默认 disabled（紧急备用） |

## 2. 包列表（PACKAGES 参数，flash 内）

```
+dropbear +curl +block-mount +blockd +fdisk +e2fsprogs +xfsprogs +nano +micro
```
- SSH 用 **dropbear**（OpenWrt 生态最轻 sshd；"libressh" 不存在——LibreSSL 是 TLS 库）
- 凭据：root 密码登录，首次开机强制设置密码（禁空密码）
- micro 为 Go 静态二进制，若压缩后超 IMAGE_SIZE(32448k) 则 micro 改入 ext4、flash 留 nano
- 排除：luci 全家桶、SFE

## 3. flash 配置（files/ 合入，保持出厂默认）

| 项 | 值 | 说明 |
|---|---|---|
| LAN | 192.168.50.1/24 | 唯一出厂改动 |
| WAN | DHCP；固定 MAC 归 cloak 模块（不烧死） | 出厂默认 |
| firewall | **不动**（出厂 flow_offloading 1 / hw 0 / fullcone 1）；伪装/加速全归模块 | 出厂默认 |
| fstab | ext4(40G) is_rootfs=1（extroot）；swap 10G；XFS → /mnt/data | 基础设施（非可摘功能） |
| sysctl | vm.swappiness=5 | 基础设施 |
| wireless | radio0/1 disabled 默认 | 出厂改动之一（驱动保留） |
| timezone | Asia/Shanghai；zh 语言包装 ext4 | |
| 自定义 | 一律不打进 flash（模块在 hdd-modules/） | 寄生原则 |

## 4. 分区（用户指定）

```
/dev/sda1  ext4   40G   系统（extroot overlay + LuCI + 后续包）
/dev/sda2  swap   10G   交换（swappiness=5）
/dev/sda3  xfs    ~881GiB  数据（/mnt/data，吞吐优先）
```

## 5. 产物与验证清单

构建产物：`bin/targets/ramips/mt7621/*.squashfs-sysupgrade.bin`
刷机：breed（192.168.1.1）直接刷 sysupgrade.bin，**先设环境变量 `newifi-d2.usb_pwr_en=1`**（USB 供电），bootloader 分区名 u-boot

验证清单：
1. **出厂基线**：刷机后即"极好的路由器"（SSH + 默认防火墙 + 硬件加速出厂态可开）
2. cloak 启用后：`nft list ruleset` 确认 ttl 规则位置；WAN 侧抓包 TTL 一致性（64/128 设备 → 统一 64）
3. accel：hw-on 后 `nft list flowtable` 见 flags offload；hw-off 回退
4. 硬盘：ext4 extroot 生效（df / 指向 ext4）、swap 挂上、XFS 挂 /mnt/data
5. portal：认证成功/保活重登日志；掉线自动重登
6. **模块摘除回退**：cloak/portal remove.sh 后配置与出厂一致

## 6. 构建步骤

```
cd /mnt/hdd/build-staff/immortalwrt-imagebuilder-25.12.1-ramips-mt7621.Linux-x86_64
make image PROFILE=d-team_newifi-d2 PACKAGES="..." FILES=<newifi3/files>
```
（repositories 已补丁 file:///mnt/hdd/build-staff/pool/...，离线可用）

## 7. 待实机后提供（配置驱动，不重编译）

- 门户 URL / 页面结构 / 挑战码机制 / 证书情况（H3C）
- **WAN 是否发放公网 IPv6**（决定 wan6 模块 A/B/保持 OFF）
- WAN 侧 TTL 实测结果、hw offload 实机稳定性
- 首次刷机验证（breed 环境变量、extroot 装配）
