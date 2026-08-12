#!/bin/sh
# wan6 形态 A（双栈）：WAN DHCPv6-PD + LAN 分发 v6
# 前提：校园网 WAN 发放公网 v6 前缀（到校实测确认后再用）。
# 注意：此形态下 LAN 设备各自持有 v6 地址 → v6 维度暴露多设备身份（伪装打折）。

DEV=$(uci -q get network.wan6.device)
[ -z "$DEV" ] && DEV=$(uci -q get network.wan.device)   # 与 WAN 对齐，实机以 uci show network.wan 为准

uci -q set network.wan6=interface
uci -q set network.wan6.proto='dhcpv6'
uci -q set network.wan6.device="$DEV"
uci -q set network.wan6.reqaddress='try'
uci -q set network.wan6.reqprefix='auto'   # 请求前缀 → 下发给 LAN
uci -q delete network.wan6.disabled
uci -q set network.lan.ipv6='1'
uci -q set network.lan.ip6assign='60'
uci commit network
/etc/init.d/network restart
echo "[wan6] A: dual-stack (LAN gets IPv6, multi-identity visible on v6)"
