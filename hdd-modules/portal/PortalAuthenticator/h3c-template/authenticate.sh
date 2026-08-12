#!/bin/sh
# (C) H3C 模板（主模块）：学校网关已确认 H3C（华三）。
# 当前为配置驱动框架：URL/字段/挑战码全部来自 /etc/portal.conf，不写死协议细节。
# 刷机后：DUMP=1 抓登录页 → 按 H3C 实际页面填配置 → 重试。
# 典型 H3C IMC 网页认证为表单 POST（默认字段 userId/password），部分带 JS 挑战码（配 CHALLENGE_CMD）。
. /etc/portal.conf
[ -n "$PORTAL_USER" ] && [ -n "$PORTAL_PASS" ] || { echo "portal.conf 未填凭据"; exit 2; }

UA=${UA:-Mozilla/5.0}

# 调试：抓登录页供人工分析（首次刷机必跑，产物 /tmp/portal_dump.html）
if [ "${DUMP:-0}" = "1" ]; then
  curl -s -m 15 -k -A "$UA" "$PORTAL_URL" > /tmp/portal_dump.html
  echo "登录页已存 /tmp/portal_dump.html（字段名/挑战码看这里）"
fi

# 挑战码 hook：若 H3C 页面用挑战机制，在此配置一次性命令（输出挑战值到 stdout）
CHALLENGE_VAL=""
if [ -n "$CHALLENGE_CMD" ]; then
  CHALLENGE_VAL=$($CHALLENGE_CMD 2>/dev/null)
fi

# 认证 POST（字段按 H3C 实际命名，默认 userId/password）
H3C_URL=${H3C_URL:-$PORTAL_URL}
eval "curl -s -m 20 -k -A \"$UA\" -d \"${USER_FIELD:-userId}=$PORTAL_USER\" -d \"${PASS_FIELD:-password}=$PORTAL_PASS\" ${CHALLENGE_VAL:+-d \"challenge=$CHALLENGE_VAL\"} \"$H3C_URL\"" > /tmp/h3c_resp.html
if grep -qE "${SUCCESS_MARKER:-success|成功|logout|欢迎}" /tmp/h3c_resp.html; then
  exit 0
else
  echo "H3C 认证失败，响应已存 /tmp/h3c_resp.html（DUMP=1 可复查）"
  exit 1
fi
