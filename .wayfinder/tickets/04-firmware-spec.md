---
title: 固件构成规格确认
type: grilling
label: wayfinder:grilling
status: closed
blocked-by: [02-accel-vs-cloak.md]
blocks: []
parent: ../map.md
---

## Question

固件构成全部细节锁定（票 2 解出后过一遍）：

- 包列表逐项确认（含 WiFi 备用组件、USB/XFS/ext4、SFE 是否入包）
- network/dhcp/firewall/fstab/wireless 配置细节（flowtable 语法、extroot、swapfile、伪装规则）
- build.sh 与 README 形态；产物验证清单（认证日志、offload 状态、硬盘挂载、TTL 检查）

## Resolution

grilling 于 2026-08-12 完成 —— **规格锁定**，可交普通会话构建。

### 包列表（flash 内，PACKAGES 参数）

```
+dropbear +curl +block-mount +blockd +fdisk +e2fsprogs +xfsprogs +nano +micro
-*默认 luci 全家桶移除*（base-files/kernel/libc/firewall4/nftables/dnsmasq 等随默认保留）
```
- SSH 实现：用户提出"libressh"——**不存在该包**（LibreSSL 是 TLS 库非 sshd；OpenSSH 的 sshd 即 openssh-server 反而更大）。**dropbear 即 OpenWrt/ImmortalWrt 最轻 SSH 服务端（~200K）**，保持 dropbear（满足"更轻量"诉求的正解）。
- 凭据：root 密码登录，首次开机强制设置密码（禁空密码）。
- 编辑：**nano + micro 都入 flash**（用户指定；micro 为 Go 静态二进制较大，若压缩后超 IMAGE_SIZE 则 micro 改入 ext4、flash 留 nano——构建时按体积定）。
- WiFi 驱动全部保留（默认 radio off，紧急备用）。
- 排除：luci 全家桶、SFE（官方不存在）。

### 配置细节（FILES=files/ 合入）

| 项 | 值 |
|---|---|
| LAN | `192.168.50.1/24`（用户指定） |
| WAN | DHCP；`wan6` 禁用；WAN MAC 固定 |
| firewall | `flow_offloading 1` + `fullcone 1`；`flow_offloading_hw 0` 默认（可选增强档，切换脚本一键开启） |
| 伪装 | `/etc/nftables.d/` 自定义规则：Lan→Wan forward 链 `ip ttl set 64`（软分载档完整生效） |
| fstab | ext4（40G）`is_rootfs=1`（extroot overlay）；swap 10G；XFS（剩余 ~881GiB）→ `/mnt/data` |
| sysctl | `vm.swappiness=5`（用户：swap 权重 5%） |
| wireless | radio0/1 默认 disabled（驱动保留） |
| timezone | `Asia/Shanghai`；语言包（zh）**装 ext4**（flash 纯 SSH 无需 UI 语言包） |
| portal | `/etc/portal.conf`（root-only）+ `PortalAuthenticator/`（A/B/C）+ `AuthenticatorTriggers/`（a/b/c），init.d 管理 |

### 分区（用户指定）

```
/dev/sda1  ext4   40G  系统（extroot overlay + LuCI + 后续包）
/dev/sda2  swap   10G  交换（swappiness=5）
/dev/sda3  xfs    ~881GiB 数据（/mnt/data，吞吐优先）
```

### build.sh / README 形态

- `build.sh`：离线 `make image PROFILE=d-team_newifi-d2 PACKAGES="..." FILES=files/`（repositories 已补丁 file://）；产物 bin/targets/.../squashfs-sysupgrade.bin
- README（中文）：breed 刷机步骤（**先设环境变量 `newifi-d2.usb_pwr_en=1`**，分区名 u-boot，192.168.1.1 Web 刷 sysupgrade）、首次登录改密、ext4/extroot/swap 装配说明、portal 配置指南（H3C）

### 产物验证清单

1. WAN 侧实际发包 **TTL 一致性**（不同初始 TTL 设备 NAT 后统一 64，需检测设备抓包）
2. offload 状态：`nft list flowtable` 可见 ft / 软分载生效；hw 档切换后 flowtable flags offload
3. 硬盘：ext4 extroot 生效（`df /` 指向 ext4）、swap 挂上、XFS 挂 `/mnt/data`
4. portal 认证日志：认证成功/保活重登记录正常
5. 掉线自动重登（触发模式验证）
