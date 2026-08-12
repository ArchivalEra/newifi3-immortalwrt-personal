#!/bin/sh
# portal 模块摘除：删除认证器/触发器/配置/init.d，系统回退出厂路由器。

/etc/init.d/portal-keepalive stop 2>/dev/null || true
/etc/init.d/portal-keepalive disable 2>/dev/null || true
rm -f /etc/init.d/portal-keepalive
rm -rf /etc/portal
rm -f /etc/portal.conf
echo "[portal] removed: system back to stock router (no auth logic)"
