#!/bin/sh
# (B) 录制重放：按捕获的认证流程重放。
# 录制方法（刷机后实机操作）：
#   1. 浏览器 DevTools (F12) → Network → 勾选 Preserve log → 走一遍登录
#   2. 找到认证 POST 请求 → 右键 Copy as cURL → 存为 capture
#   3. 或 tcpdump 抓包后用 'Copy as cURL' 转存
# capture 文件：/etc/portal/record-replay/capture（每行一个完整 curl 命令，占位符 %USER%/%PASS% 替换）
. /etc/portal.conf
RECORD=${RECORD_FILE:-/etc/portal/record-replay/capture}
if [ ! -f "$RECORD" ]; then
  echo "未录制认证流程（$RECORD 不存在）。按 README 录制后重试。"
  exit 2
fi

sed -e "s/%USER%/$PORTAL_USER/g" -e "s/%PASS%/$PORTAL_PASS/g" "$RECORD" > /tmp/replay.sh
if sh /tmp/replay.sh; then
  exit 0
else
  echo "重放失败（见 /tmp/replay.sh 可调试）"; exit 1
fi
