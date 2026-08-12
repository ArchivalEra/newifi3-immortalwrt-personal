#!/bin/sh
# portal 模块安装：部署 H3C 校园网认证器 + 触发器到系统。
# 寄生模块：remove.sh 摘除后系统回退出厂路由器。
# 刷机后需填写 /etc/portal.conf（H3C 页面结构待实机抓取）。

set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST=/etc/portal
CONF=/etc/portal.conf

# 1. 部署认证器 + 触发器
rm -rf "$DEST"
mkdir -p "$DEST"
cp -r "$SRC/PortalAuthenticator" "$DEST/"
cp -r "$SRC/AuthenticatorTriggers" "$DEST/"
chmod -R a+rX "$DEST"

# 2. 生成凭据配置模板（root-only）
if [ ! -f "$CONF" ]; then
cat > "$CONF" <<'EOF'
# H3C 校园网认证配置（root-only，勿含换行泄露给其他用户）
# 刷机后按实机页面填写；H3C 页面结构待实机抓取后由用户提供
PORTAL_URL=https://portal.example.edu.cn/   # 登录页 URL（HTTPS 优先；自签证书 curl 需 -k）
PORTAL_USER=
PORTAL_PASS=
PORTAL_MODE=h3c-template                    # h3c-template | generic-form | record-replay
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
PROBE_URL=http://example.edu.cn/            # 连通性探针（被重定向到门户=掉线）
TRIGGER=keepalive-daemon                    # keepalive-daemon(5min) | lazy(15-30min) | manual
EOF
chmod 600 "$CONF"
fi

# 3. 注册 init.d（触发器按 TRIGGER 配置选择模式）
cat > /etc/init.d/portal-keepalive <<'EOF'
#!/bin/sh /etc/rc.common
START=99
STOP=1
start() { [ -f /etc/portal.conf ] && /etc/portal/AuthenticatorTriggers/keepalive-daemon/run.sh; }
stop() { killall -q portal-keepalive 2>/dev/null; }
EOF
chmod +x /etc/init.d/portal-keepalive
/etc/init.d/portal-keepalive enable

echo "[portal] installed. 编辑 /etc/portal.conf（root-only）填真实凭据后: /etc/init.d/portal-keepalive start"
echo "        摘除: hdd-modules/portal/remove.sh"
