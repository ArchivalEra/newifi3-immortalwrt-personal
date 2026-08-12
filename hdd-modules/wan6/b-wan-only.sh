#!/bin/sh
# wan6 形态 B（仅 WAN）：路由器自身 WAN 有 v6，LAN 不分发 —— 伪装完整保留
# 适用：校园网发公网 v6 但不想 LAN 暴露多设备身份；或只需要 v6 连通性测试。

DEV=$(uci -q get network.wan6.device)
[ -z "$DEV" ] && DEV=$(uci -q get network.wan.device)

uci -q set network.wan6=interface
uci -q set network.wan6.proto='dhcpv6'
uci -q set network.wan6.device="$DEV"
uci -q set network.wan6.reqaddress='try'
uci -q set network.wan6.reqprefix='no'    # 不请求前缀 → 不分发
uci -q delete network.wan6.disabled
uci -q set network.lan.ipv6='0'           # 明确不向 LAN 分发
uci -q delete network.lan.ip6assign
uci commit network
/etc/init.d/network restart
echo "[wan6] B: WAN-only IPv6 (LAN stays v4-only, cloak intact)"
