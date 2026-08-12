#!/bin/sh
# 认证分发器：按 /etc/portal.conf 的 PORTAL_MODE 调对应认证器（A/B/C）
. /etc/portal.conf
MODE=${PORTAL_MODE:-h3c-template}
AUTH=/etc/portal/PortalAuthenticator/$MODE/authenticate.sh
[ -x "$AUTH" ] || { echo "认证器不存在: $MODE (PORTAL_MODE)"; exit 2; }
exec "$AUTH"
