# wayfinder:map — newifi3 校园网伪装网关固件

## Destination

锁定本固件的完整规格：**加速组合、伪装机制、portal 认证框架、包列表、磁盘方案**——以规格文档收尾，之后一次普通会话即可直接构建出 breed 可刷的 ImmortalWrt 25.12.1 镜像。地图只产出决策，不产出构建。

## Notes

- 领域：MT7621 路由器（ramips/mt7621）、校园网 Web portal 认证、PPE 硬件加速/SFE、设备指纹伪装、NAS（ext4 系统盘 + XFS 数据盘）
- HITL 票用 /grilling 对话式推进（用户本人参与）；AFK 票用 research 子代理
- 用户硬性偏好：底座 **ImmortalWrt 25.12.1（Stable, 2026-07-06）**；"硬件加速的所有相关选项"都要入选；伪装诉求"所有子网设备伪装为一个且 UA 正常"；WiFi 驱动保留、默认 radio 关（备用顶上）；flash 上纯 SSH、LuCI 之后装进 ext4；**只改动 newifi3/ 文件夹**（仓库是 rime/plum，不碰它的 git/issues）；中文交流
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

## Not yet specified

- 校园网认证网关品牌：**H3C（华三）**——用户已确认（票 3）；portal URL/表单结构仍未知
- USB 硬盘供电/识别、实机硬分载与 SFE 稳定性、breed 首刷实测（需硬件）
- 伪装清单中 TCP 时间戳/窗口大小等次要指纹的取舍（可能随票 2 解出）

## Out of scope

- RouterOS（无 MT7621 版本）
- ThinLTO（IB 无编译环节；MIPS 内核不支持）
- S905 电视盒子（另一项目）
- 华为 AX3000 固件改造（仅作 AP 桥接使用）
- 共享协议（Samba/FTP/NFS —— 用户明确暂不关心）
- U 盘扩容（32MB flash 足够）
