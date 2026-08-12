#!/bin/sh
# 连通性探测：探针 URL 被重定向到门户 / 返回登录页特征 → 判定掉线（exit 1）
# 在线 → exit 0
. /etc/portal.conf
[ -n "$PROBE_URL" ] || PROBE_URL="http://example.edu.cn/"
UA=${UA:-Mozilla/5.0}

FINAL=$(curl -s -o /dev/null -w '%{url_effective}' -L -m 10 -A "$UA" "$PROBE_URL")
case "$FINAL" in
  *"${PORTAL_HOST:-portal}"*|*login*|*auth*|*imc*|*srun*|*h3c*)
    echo "detect: redirected to portal ($FINAL)"; exit 1;;
esac

# 内容级检测：响应若为登录页（含 form+password/login 特征）判定掉线
BODY=$(curl -s -L -m 10 -A "$UA" "$PROBE_URL")
case "$BODY" in
  *"password"*"form"*|*"login"*"form"*)
    echo "detect: login page served instead of probe"; exit 1;;
esac
exit 0
