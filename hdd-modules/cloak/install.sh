#!/bin/sh
# cloak 模块安装：启用"全子网设备伪装为一个"的身份统一层。
# 可摘除：remove.sh 恢复系统出厂默认（硬件加速不受限）。
# 需 root 运行（uci / nft 均需权限）。

set -e

MOD=/etc/cloak
WAN_IF=${WAN_IF:-$(uci -q get network.wan.device)}   # 默认取 WAN 设备（eth0.2 等，实机确认）
[ -z "$WAN_IF" ] && { echo "无法确定 WAN 设备，请设置 WAN_IF=... 重试"; exit 1; }

mkdir -p "$MOD"

# --- 1. TTL 统一 64 的 nftables 规则（fw4 include） ---
# 注意：规则必须位于 fw4 forward 链的 flow offload 之前，软分载下方可逐包生效；
#       实机验证：nft list ruleset | grep -n ttl（若在 flow offload 之后需改用 priority 更早的 hook）
cat > /etc/nftables.d/10-cloak.nft <<EOF
# cloak: unify TTL on LAN->WAN forward (clamp to 64)
add rule inet fw4 forward iifname "br-lan" oifname "$WAN_IF" ip ttl set 64
EOF

# --- 2. 保证软分载（TTL 逐包修正要求） ---
uci -q set firewall.@defaults[0].flow_offloading='1'
uci -q set firewall.@defaults[0].flow_offloading_hw='0'
uci -q set firewall.@defaults[0].fullcone='1'
uci commit firewall

# --- 3. WAN 固定 MAC（可配置；不配置则跳过） ---
if [ -n "$WAN_MAC" ]; then
  uci -q set network.wan.macaddr="$WAN_MAC"
  uci commit network
  echo "$WAN_MAC" > "$MOD/wan_mac"
fi

# --- 4. 生效 ---
/etc/init.d/firewall restart 2>/dev/null || true
/etc/init.d/network restart 2>/dev/null || true

echo "[cloak] enabled: TTL=64 unified (soft offload guaranteed), WAN MAC=${WAN_MAC:-unchanged}"
echo "        验证: WAN 侧抓包 TTL 一致性；摘除: hdd-modules/cloak/remove.sh"
