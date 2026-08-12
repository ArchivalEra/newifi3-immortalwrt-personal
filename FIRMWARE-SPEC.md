# Newifi3 校园网伪装网关固件 — 规格锁定 (FIRMWARE-SPEC)

> 状态：**规格锁定**（wayfinder 4 票全闭，2026-08-12）
> 底座：ImmortalWrt 25.12.1 Stable（2026-07-06，apk 包格式，kernel 6.12.94）
> 构建：Image Builder 离线（repositories 已补丁 file://），免编译

---

## 1. 核心决策摘要

| 维度 | 决策 |
|---|---|
| 角色 | 纯有线主干网关；无线分流华为 AX3（WiFi6 AP 桥接）；S905 一体机属另一项目 |
| 伪装默认档 | 软分载（flow_offloading 1 + fullcone 1）+ nft `ip ttl set 64` 逐包修正 + WAN 固定 MAC + 单 IP NAT + IPv6 默认关 + UA 正常 |
| IPv6 模块 | **默认关**（伪装完整）；`hdd-modules/wan6/` 放硬盘，三形态：OFF / A 双栈（WAN PD+LAN 分发）/ B 仅 WAN（LAN 不分发，伪装保留）——到校实测校园网是否发公网 v6 后决定（用户记忆里不发，待实测确认） |
| 加速可选档 | `flow_offloading_hw 1`（PPE 硬分载）保留为可选增强档，配置双份 + 一键切换脚本，**默认不启用**（规避 openwrt#24459 watchdog 风险）；SFE 官方不存在，排除 |
| Portal | 学校网关为 **H3C**；认证器 `PortalAuthenticator/`（A 通用表单 / B 录制重放 / C H3C 模板）+ 触发器 `AuthenticatorTriggers/`（a 常驻保活 5min / b 慵懒 15-30min / c 手动）；配置驱动不重编译；HTTPS 优先，不自创加密 |
| 存储 | 1T HDD USB3：ext4 40G（extroot overlay）+ swap 10G（swappiness=5）+ XFS 剩余 → /mnt/data |
| flash | 纯 SSH（dropbear）+ 伪装 + portal + 引导挂盘；LuCI 之后 `apk add` 到 ext4 |
| WiFi | 驱动全部保留，radio 默认 disabled（紧急备用） |

## 2. 包列表（PACKAGES 参数，flash 内）

```
+dropbear +curl +block-mount +blockd +fdisk +e2fsprogs +xfsprogs +nano +micro
```
- SSH 用 **dropbear**（OpenWrt 生态最轻 sshd，~200K；用户提到的 "libressh" 不存在——LibreSSL 是 TLS 库，OpenSSH 反而更大）
- 凭据：root 密码登录，首次开机强制设置密码（禁空密码）
- micro 为 Go 静态二进制，若压缩后超 IMAGE_SIZE(32448k) 则 micro 改入 ext4、flash 留 nano
- 排除：luci 全家桶、SFE（官方不存在）

## 3. 配置细节（FILES=files/ 合入）

| 项 | 值 |
|---|---|
| LAN | 192.168.50.1/24 |
| WAN | DHCP；固定 MAC；IPv6 默认关（wan6 模块放硬盘，A/B 形态到校实测公网 v6 后启用） |
| firewall | flow_offloading 1 + fullcone 1；flow_offloading_hw 0 默认（可选档脚本切换） |
| 伪装 | /etc/nftables.d/ 自定义规则：Lan→Wan forward `ip ttl set 64` |
| fstab | ext4(40G) is_rootfs=1（extroot）；swap 10G；XFS → /mnt/data |
| sysctl | vm.swappiness=5 |
| wireless | radio0/1 disabled 默认 |
| timezone | Asia/Shanghai；zh 语言包装 ext4（flash 纯 SSH 无需 UI 语言包） |
| portal | /etc/portal.conf（root-only）+ 认证器/触发器目录，init.d 管理 |

## 4. 分区（用户指定）

```
/dev/sda1  ext4   40G   系统（extroot overlay + LuCI + 后续包）
/dev/sda2  swap   10G   交换（swappiness=5）
/dev/sda3  xfs    ~881GiB  数据（/mnt/data，吞吐优先）
```

## 5. 产物与验证清单

构建产物：`bin/targets/ramips/mt7621/*.squashfs-sysupgrade.bin`
刷机：breed（192.168.1.1）直接刷 sysupgrade.bin，**先设环境变量 `newifi-d2.usb_pwr_en=1`**（breed 默认关 USB 供电），bootloader 分区名 u-boot

验证清单：
1. WAN 侧实际发包 TTL 一致性（不同初始 TTL 设备 NAT 后统一 64，需检测设备抓包）
2. offload 状态：`nft list flowtable`；hw 档切换后 flags offload
3. 硬盘：ext4 extroot 生效（df / 指向 ext4）、swap 挂上、XFS 挂 /mnt/data
4. portal 认证日志：认证成功/保活重登记录正常；掉线自动重登（触发模式验证）

## 6. 构建步骤

```
cd /mnt/hdd/build-staff/immortalwrt-imagebuilder-25.12.1-ramips-mt7621.Linux-x86_64
make image PROFILE=d-team_newifi-d2 PACKAGES="..." FILES=<newifi3/files>
```
（repositories 已补丁 file:///mnt/hdd/build-staff/pool/...，离线可用）

## 7. 待实机后提供（配置驱动，不重编译）

- 门户 URL / 页面结构 / 挑战码机制 / 证书情况（H3C）
- **WAN 是否发放公网 IPv6**（决定 v6 模块启用 A/B/保持 OFF——用户记忆里不发，待实测）
- WAN 侧 TTL 实测结果、hw offload 实机稳定性
- 首次刷机验证（breed 环境变量、extroot 装配）
