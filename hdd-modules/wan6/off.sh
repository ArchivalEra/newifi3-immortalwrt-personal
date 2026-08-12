#!/bin/sh
# wan6 形态 OFF（默认出厂态）：WAN/LAN 均无 IPv6，v4 单 IP NAT，伪装完整
# 到校实测校园网是否发放公网 v6 前，保持此状态。

uci -q set network.wan6.disabled='1'   # 关闭 WAN v6
uci -q set network.lan.ipv6='0'        # 不向 LAN 分发 v6（含 RA/地址）
uci commit network
/etc/init.d/network restart
echo "[wan6] OFF: IPv6 disabled (cloak complete)"
