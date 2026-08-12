#!/bin/sh
# accel 模块: 开启 PPE 硬件流卸载（可选增强档，默认关）
# 警告: 与 cloak 模块互斥（TTL 逐包修正失效）；已知稳定性风险见 README。

uci -q set firewall.@defaults[0].flow_offloading_hw='1'
uci commit firewall
/etc/init.d/firewall restart
echo "[accel] hw offload ON (flow_offloading_hw=1). 注意: 若 cloak 已启用, TTL 修正失效。"
echo "       关闭: hdd-modules/accel/hw-off.sh"
