#!/bin/sh
# (A) 通用表单解析器：抓登录页 → 解析 form action + hidden 字段 → POST 账号密码 → 成功标记验证
# 配置（/etc/portal.conf）：PORTAL_URL / USER_FIELD / PASS_FIELD / SUCCESS_MARKER / UA
# 退出码：0=认证成功 1=失败 2=未配置
. /etc/portal.conf
[ -n "$PORTAL_USER" ] && [ -n "$PORTAL_PASS" ] || { echo "portal.conf 未填 PORTAL_USER/PORTAL_PASS"; exit 2; }

UA=${UA:-Mozilla/5.0}
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# 1. 抓登录页
curl -s -m 15 -k -A "$UA" "$PORTAL_URL" > "$TMP/page.html" || { echo "fetch login page failed"; exit 1; }

# 2. 解析 form action（双引号/单引号/无 action 三态）
ACTION=$(grep -oE '<form[^>]*action="[^"]*"' "$TMP/page.html" | head -1 | sed 's/.*action="//;s/"//')
[ -z "$ACTION" ] && ACTION=$(grep -oE "<form[^>]*action='[^']*'" "$TMP/page.html" | head -1 | sed "s/.*action='//;s/'//")
[ -z "$ACTION" ] && ACTION="$PORTAL_URL"
case "$ACTION" in http*) ;; /*) ACTION="$(echo "$PORTAL_URL" | sed 's#://[^/]*#://'"$(echo "$PORTAL_URL" | cut -d/ -f3)"'#')$ACTION";; *) ACTION="${PORTAL_URL%/}/$ACTION";; esac

# 3. hidden 字段（token/挑战码等）拼成 -d 参数
HIDDEN=$(grep -oE '<input[^>]*type="hidden"[^>]*>' "$TMP/page.html" | \
  sed -E 's/.*name="([^"]*)".*value="([^"]*)".*/-d "\1=\2"/' | tr '\n' ' ')

# 4. 字段名（可配置，默认 username/password）
UF=${USER_FIELD:-username}; PF=${PASS_FIELD:-password}

# 5. POST 并验证成功标记
eval "curl -s -m 20 -k -A \"$UA\" $HIDDEN -d \"$UF=$PORTAL_USER\" -d \"$PF=$PORTAL_PASS\" \"$ACTION\"" > "$TMP/resp.html"
if grep -qE "${SUCCESS_MARKER:-success|登录成功|欢迎}" "$TMP/resp.html"; then
  exit 0
else
  echo "auth failed (no success marker). 响应: $TMP/resp.html（DUMP=1 保留调试）"
  [ "${DUMP:-0}" = "1" ] && cp "$TMP/resp.html" /tmp/portal_resp.html
  exit 1
fi
