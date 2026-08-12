# Newifi3 校园网伪装网关 — 构建与使用

ImmortalWrt 25.12.1（Stable）· ramips/mt7621 · d-team_newifi-d2 · **离线构建**

> 规格：见 `FIRMWARE-SPEC.md`（已锁定）。wayfinder 决策记录：`.wayfinder/`。

---

## 两个大类（明确边界）

| ① 放路由器上（烧进 flash 固件） | ② 放硬盘上（不烧 flash） |
|---|---|
| **出厂好路由器**：ImmortalWrt 出厂默认 + 唯一改动 LAN `192.168.50.1/24` + radio 默认关 + v6 默认关 + fstab 挂盘引导（extroot/swap/XFS）+ swappiness=5 + 时区上海 | **全部寄生模块**：`hdd-modules/`（cloak 伪装 / portal 认证 / accel 加速开关 / wan6 IPv6），刷机挂盘后拷到 `/mnt/data/` 按需 install |
| 极简包：dropbear / curl / block-mount / fdisk / e2fsprogs / xfsprogs / nano / micro | 之后 LuCI 等 `apk add` 到 ext4 overlay |
| 产出：`sysupgrade.bin` | **摘除模块 = 回退出厂默认路由器，硬件加速不受任何限制** |

fallback 链：模块 `remove.sh` → 出厂配置；`firstboot` → 纯出厂镜像。

---

## 一、构建（离线，不需联网）

```
cd /mnt/hdd/build-staff/immortalwrt-imagebuilder-25.12.1-ramips-mt7621.Linux-x86_64
# （物料清单见 /mnt/hdd/build-staff/MANIFEST.md；repositories 已补丁 file:// 本地 pool）

cd <newifi3> && ./build.sh
# 产物: bin/targets/ramips/mt7621/immortalwrt-*-d-team_newifi-d2-squashfs-sysupgrade.bin
```

## 二、刷机（breed）

1. 下载 `breed-mt7621-newifi-d2.bin`（breed.hackpascal.net），进 breed Web（按住 reset 上电，浏览器 192.168.1.1）
2. **⚠ 先设环境变量**：`newifi-d2.usb_pwr_en=1`（breed 默认关 USB 供电，否则 1T 硬盘没电）
3. breed 中刷入 `sysupgrade.bin`（bootloader 分区名 u-boot；本固件无 factory 镜像，直接刷 sysupgrade）
4. 刷完 breed 里"恢复出厂设置"再启动

## 三、首次配置（路由器上）

```
ssh root@192.168.50.1        # 首次 root 密码为空（banner 有提示）
passwd                       # 立即设置 root 密码（出厂要求）
```

## 四、硬盘装配（extroot / swap / XFS）

> 分区方案（用户指定）：`sda1 ext4 40G`（系统）+ `sda2 swap 10G` + `sda3 xfs 剩余`（数据）
> fstab 已预置（files/），未插盘/未格式化时自动跳过 → flash overlay 照常（fallback 天然成立）

```
# 1. 分区 + 格式化（USB 盘，确认设备名！fdisk 里核对容量）
fdisk /dev/sda        # 建 sda1(ext4 40G) sda2(swap 10G) sda3(xfs 剩余)
mkfs.ext4 /dev/sda1
mkswap /dev/sda2
mkfs.xfs -f /dev/sda3

# 2. 重启 → block-mount 自动挂载：
#    sda1 → extroot overlay（df / 应指向 /dev/sda1）
#    sda2 → swap（free 可见）
#    sda3 → /mnt/data（df 可见）

# 3. 若设备名变了（sdb 等）：block detect > /etc/config/fstab 重新生成（UUID 方式）
```

## 五、装硬盘模块（②类，全部寄生）

```
scp -r hdd-modules/ root@192.168.50.1:/mnt/data/
ssh root@192.168.50.1
/mnt/data/hdd-modules/cloak/install.sh      # 伪装：TTL 统一 64 + 软分载 + 固定 MAC（可设 WAN_MAC=xx）
/mnt/data/hdd-modules/portal/install.sh     # 认证：部署后编辑 /etc/portal.conf 填凭据
/mnt/data/hdd-modules/accel/hw-on.sh        # 可选：硬件加速增强档（与 cloak 互斥，慎用）
/mnt/data/hdd-modules/wan6/a-dual-stack.sh  # 可选：校园网有公网 v6 时启用（默认 OFF）
```

### portal 认证配置（H3C，刷机后实机调）

```
# 抓登录页分析字段（首次必做）
DUMP=1 /etc/portal/PortalAuthenticator/h3c-template/authenticate.sh
cat /tmp/portal_dump.html        # 看 URL/字段名/挑战码机制
# 填 /etc/portal.conf：PORTAL_URL / PORTAL_USER / PORTAL_PASS / USER_FIELD / SUCCESS_MARKER
# 启动保活
service portal-keepalive start
logread | grep portal-           # 看认证/保活日志
```

### 模块摘除（回退出厂）

```
/mnt/data/hdd-modules/cloak/remove.sh
/mnt/data/hdd-modules/portal/remove.sh
/mnt/data/hdd-modules/accel/hw-off.sh
/mnt/data/hdd-modules/wan6/off.sh
```

## 六、LuCI 装到 ext4（可选，之后）

```
apk add luci luci-theme-material luci-i18n-base-zh-cn   # 在 extroot overlay 上
service uhttpd enable && service uhttpd start
```

## 七、验证清单

1. **出厂基线**：刷机后即"极好的路由器"（SSH 可用、防火墙默认、硬件加速出厂态可开）
2. cloak 后 TTL：`nft list ruleset | grep ttl`；WAN 侧抓包看不同设备 NAT 后 TTL 统一 64
3. accel：hw-on 后 `nft list flowtable` 见 flags offload；hw-off 回退
4. 硬盘：`df /` 指向 ext4、`free` 见 swap、`df /mnt/data` 见 XFS
5. portal：认证成功/保活日志；拔线重插验证自动重登
6. **模块摘除回退**：remove.sh 后配置与出厂一致

## 待实机补充（配置驱动，不重编译）

- H3C 门户 URL / 字段 / 挑战码 / 证书情况
- WAN 是否发放公网 IPv6（决定 wan6 A/B/OFF）
- WAN 侧 TTL 实测、hw offload 实机稳定性
