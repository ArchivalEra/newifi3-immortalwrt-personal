#!/bin/sh
# cloak 模块摘除：删除全部伪装痕迹，系统回退 ImmortalWrt 出厂默认。
# 硬件加速不再受模块约束（可用 accel/hw-on.sh 或 LuCI 开启）。

set -e

# 1. 删 nft 规则
rm -f /etc/nftables.d/10-cloak.nft

# 2. firewall 恢复出厂默认（25.12 出厂: flow_offloading=1, hw=0, fullcone=1）
uci -q set firewall.@defaults[0].flow_offloading='1'
uci -q set firewall.@defaults[0].flow_offloading_hw='0'
uci -q set firewall.@defaults[0].fullcone='1'
uci commit firewall

# 3. 还原 WAN MAC（若 install 时设置过）
if [ -f /etc/cloak/wan_mac ]; then
  uci -q delete network.wan.macaddr
  uci commit network
  rm -f /etc/cloak/wan_mac
fi

# 4. 生效
/etc/init.d/firewall restart 2>/dev/null || true
/etc/init.d/network restart 2>/dev/null || true

echo "[cloak] removed: system back to ImmortalWrt defaults (hw accel free to use)"
