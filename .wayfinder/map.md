# wayfinder:map — newifi3 校园网伪装网关固件

## Destination

锁定本固件的完整规格：**加速组合、伪装机制、portal 认证框架、包列表、磁盘方案**——以规格文档收尾，之后一次普通会话即可直接构建出 breed 可刷的 ImmortalWrt 25.12.1 镜像。地图只产出决策，不产出构建。

## Notes

- 领域：MT7621 路由器（ramips/mt7621）、校园网 Web portal 认证、PPE 硬件加速/SFE、设备指纹伪装、NAS（ext4 系统盘 + XFS 数据盘）
- HITL 票用 /grilling 对话式推进（用户本人参与）；AFK 票用 research 子代理
- 用户硬性偏好：底座 **ImmortalWrt 25.12.1（Stable, 2026-07-06）**；"硬件加速的所有相关选项"都要入选；伪装诉求"所有子网设备伪装为一个且 UA 正常"；WiFi 驱动保留、默认 radio 关（备用顶上）；flash 上纯 SSH、LuCI 之后装进 ext4；**只改动 newifi3/ 文件夹**（仓库是 rime/plum，不碰它的 git/issues）；中文交流
- **架构原则（用户 08-12 声明）**：flash 固件 = ImmortalWrt 出厂默认（唯一改动 LAN 192.168.50.1/24）；一切自定义（伪装/认证/v6/加速开关）都是**寄生模块**（hdd-modules/，装硬盘）；摘除模块=回退出厂默认路由器，硬件加速不受限；fallback 永远是系统默认配置
- 用户网络流量受限：构建/大下载必须等 WiFi 环境
- 关键硬件事实（票 1 已核实）：PPE 硬件分载逐包绕开 netfilter → 固定值 TTL 改写只能软件路径；**SFE 在 25.12.1 官方 feed 中不存在**（只能自编第三方 feed，排除）；`ip ttl set 64` 在 nftables 1.1.6 可用，xt_TCPOPTSTRIP 无；mtk_ppe hw offload 可用但有已知稳定性问题（openwrt#24459 watchdog 重启等）；breed 默认关 USB 供电需 `newifi-d2.usb_pwr_en=1`

## Decisions so far

<!-- 已谈定的初始决策（来自建图前的对话）；票解出的决策后续补行 -->

- 底座 ImmortalWrt 25.12.1，Image Builder 免编译；ThinLTO 排除（IB 无编译环节、MIPS 内核不支持 LTO）
- newifi3 = 纯有线主网关；WiFi 驱动保留、默认 radio 关
- WAN=DHCP（校园网），关 IPv6；WAN 固定 MAC + 单 IP NAT；设备 UA 不动，路由器 portal 请求用真实浏览器 UA
- 硬盘：ext4=系统盘（extroot overlay + swap）、XFS=数据盘（/mnt/data 只挂载）；flash 纯 SSH，LuCI 以后 opkg 装进 ext4 overlay
- 华为 AX3000 作 AP 桥接挂在 LAN 下（其固件改造见 Out of scope）
- 票1（研究）已关闭：SFE 出局；TTL 伪装 = nft `ip ttl set 64`（软分载路径）；hw offload 存在已知稳定性风险（openwrt#24459 等），默认档与切换形态待票 2 裁决；breed 刷机必须项 = 环境变量 `newifi-d2.usb_pwr_en=1`（USB 供电）+ 分区名 u-boot
- 票3（grilling）已关闭：Portal 框架 = `PortalAuthenticator/`（A 通用表单 / B 录制重放 / C H3C 模板 —— 学校网关确认为 **H3C**）+ `AuthenticatorTriggers/`（a 常驻保活 5min / b 慵懒 15-30min / c 手动，三模式共用认证器接口）；传输安全走 HTTPS（TLS ECDHE=一次性密钥）或 H3C 协议内置机制，不自创加密（服务器不认）；MT7621 无 AES 硬件引擎但登录仅几 KB、软件加密无压力；凭据 root-only、不落日志
- 票2（grilling）已关闭：**默认=伪装完整档**（软分载 flow_offloading + fullcone + nft `ip ttl set 64` 逐包修正 + WAN 固定 MAC + 单 IP NAT + UA 正常）；**hw offload=可选增强档**（配置双份+切换脚本，默认不启用，规避 #24459 watchdog 风险；用户 08-12 确认"硬件加速仍然要，作为选项"）；SFE 排除；TCP 时间戳等次要指纹先不做；**实机必测**=WAN 侧 TTL 一致性验证；拓扑：newifi3 仅有线主干，无线分流华为 AX3，S905 另一项目
- IPv6（08-12 追加）：**默认关**（伪装完整）；模块化放硬盘 `hdd-modules/wan6/`（OFF / A 双栈 / B 仅 WAN 三形态脚本），到校实测校园网是否发公网 v6 后启用（用户记忆里不发，待实测）
- 票4（grilling）已关闭 —— **规格锁定**：包=dropbear/curl/block-mount/fdisk/e2fsprogs/xfsprogs/nano/micro + 去 luci；LAN 192.168.50.1/24、WAN DHCP 固定 MAC；firewall 软分载+fullcone 默认、hw 可选档；nft TTL 伪装；ext4 40G extroot + swap 10G（swappiness=5）+ XFS 剩余→/mnt/data；时区 Asia/Shanghai、语言包装 ext4；portal 配置驱动（H3C）；build.sh 离线 make image + 中文 README（breed 刷机含 usb_pwr_en=1）+ 验证清单（TTL 一致性/flowtable/挂载/认证日志）；IPv6 默认关（模块化，见上行）
- map 已完：全部 4 票关闭，规格锁定，可交普通会话构建

## Not yet specified

- 校园网认证网关品牌：**H3C（华三）**——用户已确认（票 3）；portal URL/表单结构/挑战机制仍未知
- **WAN 是否发放公网 IPv6**（用户记忆里不发，到校实测；决定 hdd-modules/wan6 用 A/B/保持 OFF）
- USB 硬盘供电/识别（breed 环境变量 `newifi-d2.usb_pwr_en=1` 已列为刷机必须项）、实机 hw offload 稳定性、breed 首刷实测（需硬件）
- 伪装清单中 TCP 时间戳/窗口大小等次要指纹的取舍 —— **已决：先不做**（票 2，实机验证后按需追加）

## Out of scope

- RouterOS（无 MT7621 版本）
- ThinLTO（IB 无编译环节；MIPS 内核不支持）
- S905 电视盒子（另一项目）
- 华为 AX3000 固件改造（仅作 AP 桥接使用）
- 共享协议（Samba/FTP/NFS —— 用户明确暂不关心）
- U 盘扩容（32MB flash 足够）
