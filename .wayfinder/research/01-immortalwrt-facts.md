# ImmortalWrt 25.12.1 (ramips/mt7621, Newifi D2) 事实核查报告

调查日期: 2026-08-12。版本 25.12.1 已确认存在: GitHub tag `v25.12.1` (tagger date **2026-07-06T02:13:55Z**, 消息 "ImmortalWrt v25.12.1 Release")。内核为 **6.12 系列 (6.12.94)**, 包格式已切换为 apk。

---

## 1. Image Builder 与 make image 命令

- **存在**。官方下载站该目标目录下:
  `https://downloads.immortalwrt.org/releases/25.12.1/targets/ramips/mt7621/immortalwrt-imagebuilder-25.12.1-ramips-mt7621.Linux-x86_64.tar.zst`
  - 注意: 是 **.tar.zst** (zstd 压缩), 不是 .tar.xz; 解包需 `tar --zstd` 或新版 tar。
  - 同目录另有 `sha256sums`、`sha256sums.sig`、`profiles.json`、`kmods/6.12.94-1-6a2bf6a139096c2bbdc3e52f4b809523/`、`packages/`。
- **清华镜像不可用(已核实)**: `https://mirrors.tuna.tsinghua.edu.cn/immortalwrt/` 返回 **404** (根路径即 404, 镜像主页列表中也无 immortalwrt 条目)。TUNA 目前未镜像 ImmortalWrt, 请勿使用该地址。
- **可用国内镜像(已验证 HTTP 200)**: 中科大 USTC, 布局与官方一致:
  `https://mirrors.ustc.edu.cn/immortalwrt/releases/25.12.1/targets/ramips/mt7621/` (imagebuilder 与 newifi-d2 固件均在)。
- **make image 命令**(语法依据 openwrt.org Image Builder 文档; ImmortalWrt 同款):
  ```
  make image PROFILE=d-team_newifi-d2 PACKAGES="<pkg1> [<pkg2> ...]" FILES=<目录>
  ```
  - `PROFILE=d-team_newifi-d2`: profile 名来自 target/linux/ramips/image/mt7621.mk 的 `TARGET_DEVICES += d-team_newifi-d2` (可用 `make info` 列出全部 profile)。
  - `PACKAGES="..."`: 追加软件包, 包名前加 `-` 表示从默认包中移除; 25.12 已用 apk 格式, 但 PACKAGES 参数用法不变。
  - `FILES=<path>`: 将该目录内容原样合入镜像根文件系统 (不指定文件名, 指目录)。
  - 新3 (d-team_newifi-d2) 无 factory 镜像, 产物为 `squashfs-sysupgrade.bin` (另有 initramfs-kernel.bin)。

## 2. 硬件流卸载 (mtk_ppe / firewall4 hw_offload)

- **mtk_ppe 已编入 mt7621 内核**: 25.12.1 ramips/mt7621 内核配置 `config-6.12` 中 `CONFIG_NET_MEDIATEK_SOC=y`。内核 6.12 中 mtk_ppe.o/mtk_ppe_debugfs.o/mtk_ppe_offload.o 由 `CONFIG_NET_MEDIATEK_SOC` 直接编译(无独立 PPE 开关): `mtk_eth-y := mtk_eth_soc.o mtk_eth_path.o mtk_ppe.o ...`。
- **MT7621 上 PPE 实际启用**: `mtk_eth_soc.c` 中 `mt7621_data` 设置 `ppe_num = 1, offload_version = 1`(6.12 源码), 驱动初始化时调用 `mtk_ppe_init()` + `mtk_eth_offload_init()`(注册 netfilter flowtable 硬件卸载)并在 open 时 `mtk_ppe_start()`。注意 `MT7621_CAPS` 宏不含 MTK_PPE 标志, 是否启用取决于 ppe_num/offload_version 而非该 caps。
- **firewall4 语法**(fw4 源码 ruleset.uc): 启用后生成
  ```
  flowtable ft { hook ingress priority 0; devices = {...}; counter; flags offload; }
  chain forward { ... meta l4proto { tcp, udp } flow offload @ft; }
  ```
  UCI 为两个 bool 选项(fw4.uc): `option flow_offloading '1'`(软件) + `option flow_offloading_hw '1'`(硬件); 硬件不可用时 fw4 自动回退软件并告警 "Hardware flow offloading unavailable, falling back to software offloading"。
- **ImmortalWrt 25.12 默认配置**(firewall.config): `config defaults` 下 `option flow_offloading 1`(软件加速**默认开启**) + `option fullcone 1`; 硬件卸载默认关。
- **结论**: 25.12.1 的 mt7621 上 hw_offload **可用**(驱动就绪), 但**存在已知稳定性问题**:
  - openwrt/openwrt#24459 (2026-07, open): mt7621 开 hw 卸载时对 pppoe-wan 用 tcpdump 抓包触发 **watchdog 重启**(在 25.12.5/内核 6.12.94 与 24.10.5/6.6.119 均复现)。
  - openwrt/openwrt#10354 (2022, open): mt7621 硬件流卸载"只能暂时工作"。
  - openwrt/openwrt#7279 (2019): MT7621 hw flow offload 崩溃。
  - 相关: openwrt/openwrt#20869 (filogic L2TP+hw 卸载 mtk_ppe TX 路径 panic)。
  - 建议: 新3 上用软件卸载(`flow_offloading 1`)即可, 若要 hw 需自行评估上述风险。

## 3. kmod-sfe / kmod-nft-sfe

- **官方 25.12.1 二进制 feed 中不存在**: 已逐项核对 `targets/ramips/mt7621/kmods/6.12.94-1-*/` 与 `targets/ramips/mt7621/packages/` 文件列表, 无 kmod-sfe / kmod-sfe-cm / kmod-nft-sfe。
- **源码 feed 也没有**: immortalwrt/packages 仓库 net/ 目录(openwrt-25.12 与 openwrt-24.10 分支)均无 shortcut-fe/sfe 包; feeds.conf 仅有 packages/luci/routing/telephony/video。
- **结论**: SFE 不在官方 25.12.1 提供范围。需要 SFE 只能自编第三方 feed; 官方路径建议用内核自带的 flowtable 软件卸载(见第 2 点)。

## 4. nftables `ip ttl set 64` 与 xt_TCPOPTSTRIP

- **nftables 版本**: 1.1.6-r2 (package/network/utils/nftables Makefile)。
- **`ip ttl set 64` 支持(已核实)**:
  - 内核 6.12 `nft_payload.c`: 网络头(network header)写入无字段白名单限制, `nft_payload_set_eval` 直接 `skb_store_bits`, IPv4 TTL(offset 8)可写。
  - nftables 用户态 `src/proto.c` 定义了 `IPHDR_FIELD("ttl", ttl)`(IPv4, offset 8)与 `IP6HDR_FIELD("hoplimit", hop_limit)` 模板 → 语法解析支持。
  - 即 25.12.1 上 `nft add rule ... ip ttl set 64` / `ip6 hoplimit set 64` 可用; fw4 中通过 `/etc/nftables.d/*.nft` 自定义文件加入(fw4 自动 include)。
- **xt_TCPOPTSTRIP 不存在**: immortalwrt `openwrt-25.12` 分支 `package/kernel/linux/modules/netfilter.mk` 全文无 CONFIG_NETFILTER_XT_TARGET_TCPOPTSTRIP 定义; mt7621 的 config-6.12 也无该符号 → **官方 25.12.1 没有 TCPOPTSTRIP 内核模块包**(需自行编译内核模块)。
  - 相关现状: iptables TTL target 由 **kmod-ipt-ipopt**(用户态 iptables-mod-ipopt-1.8.10-r3.apk, 已确认在仓库中)提供; kmod-ipt-extra 亦存在。
  - 若目的是"统一 TTL", 直接用 nftables `ip ttl set 64` 即可, 无需 TCPOPTSTRIP。

## 5. Breed 刷机 (newifi-d2)

- **文件**: `breed-mt7621-newifi-d2.bin`, 官方地址 `https://breed.hackpascal.net/`(列表确认存在)。
  - 官方发布帖(恩山): `https://www.right.com.cn/forum/thread-161906-1-1.html` "【2022-07-26】AR/QCA/MTK Breed"。
  - 该帖注明: Newifi D2 专用版, 512MB DDR3 时序参数, 复位键 GPIO#3, WPS 键 GPIO#7。
  - **重要**: 该版 breed 默认**关闭 Newifi D2 的 USB 供电**, 需在 breed 环境变量中设 `newifi-d2.usb_pwr_en=1` 才能给 USB 口供电。
- **刷入步骤**(流程依据官方帖 + CSDN Breed 教程):
  1. 在原厂/潘多拉固件上获得 SSH 权限;
  2. `cat /proc/mtd` 确认 bootloader 分区名(OpenWrt 布局下为 **u-boot**, 0x0–0x30000; 原厂布局通常名为 Bootloader), (可选)先备份原 bootloader;
  3. 上传: `scp breed-mt7621-newifi-d2.bin root@<ip>:/tmp/`;
  4. 写入: `mtd write /tmp/breed-mt7621-newifi-d2.bin u-boot`(按第 2 步实际分区名);
  5. 断电, **按住 reset 键上电**, 数秒后浏览器访问 `192.168.1.1` 进入 breed Web 恢复台;
  6. 在 breed 中刷入 `immortalwrt-25.12.1-ramips-mt7621-d-team_newifi-d2-squashfs-sysupgrade.bin`(新3 无 factory 镜像, 直接刷 sysupgrade.bin; breed 写入 firmware 分区)。
- **注意事项**:
  - 新3 为 SPI NOR 32MB(`jedec,spi-nor`; DTS 分区: u-boot/u-boot-env/factory/firmware@0x50000), 固件大小上限 IMAGE_SIZE=32448k, 自编译固件别超;
  - breed 默认关 USB 供电(见上); 刷完建议在 breed 里"恢复出厂设置"再启动;
  - 恩山有"新3 硬件 1.1/1.2 版本差异"的说法, **本次未能在抓取的权威来源中确认**与该版本 breed 的兼容性问题, 未验证项不做结论。

---

## 未验证/无法确认项(明确说明)

- 清华 TUNA 镜像: **确认不可用(404)**——任务预设的该镜像地址不成立, 已给出 USTC 替代。
- 新3 硬件 1.1/1.2 版本与 breed 兼容性: 未找到权威来源, 不作结论。
- 25.12.1 官方 feed 中 TCPOPTSTRIP: 确认**不存在**(这即结论, 依据 netfilter.mk 与内核 config 双重核对)。
- SFE 第三方 feed 的可用性(如 lean 源码): 未调查, 不涉及官方事实。

## 主要来源

- https://downloads.immortalwrt.org/releases/25.12.1/targets/ramips/mt7621/ (imagebuilder/sha256sums/kmods/packages)
- https://mirrors.ustc.edu.cn/immortalwrt/releases/25.12.1/targets/ramips/mt7621/ (可用镜像; TUNA 404)
- https://openwrt.org/docs/guide-user/additional-software/imagebuilder (make image 语法)
- github.com/immortalwrt/immortalwrt @ openwrt-25.12: target/linux/ramips/mt7621/config-6.12, image/mt7621.mk, dts/mt7621_d-team_newifi-d2.dts, package/network/utils/nftables/Makefile, package/kernel/linux/modules/netfilter.mk, package/network/config/firewall/files/firewall.config
- torvalds/linux v6.12: drivers/net/ethernet/mediatek/Makefile、mtk_eth_soc.c、mtk_eth_soc.h; net/netfilter/nft_payload.c
- git.netfilter.org/nftables: src/proto.c (ttl/hoplimit 模板)
- github.com/openwrt/firewall4: root/usr/share/ucode/fw4.uc, root/usr/share/firewall4/templates/ruleset.uc
- GitHub issues: openwrt/openwrt #24459、#10354、#7279、#20869
- https://breed.hackpascal.net/ ; https://www.right.com.cn/forum/thread-161906-1-1.html ; https://blog.csdn.net/CoolBoySilverBullet/article/details/121077410
