#!/bin/sh
# accel 模块: 关闭 PPE 硬件流卸载（回软分载，出厂默认态）

uci -q set firewall.@defaults[0].flow_offloading_hw='0'
uci commit firewall
/etc/init.d/firewall restart
echo "[accel] hw offload OFF (flow_offloading_hw=0) — back to default. cloak TTL fix works again."
