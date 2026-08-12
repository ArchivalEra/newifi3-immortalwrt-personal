#!/bin/sh
# portal 模块安装：部署 H3C 校园网认证器 + 触发器 + 共享层到系统。
# 寄生模块：remove.sh 摘除后系统回退出厂路由器。
# 刷机后需填写 /etc/portal.conf（H3C 页面结构待实机抓取）。

set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST=/etc/portal
CONF=/etc/portal.conf

# 1. 部署认证器 + 触发器 + 共享层（probe.sh / authenticate.sh）
rm -rf "$DEST"
mkdir -p "$DEST"
cp -r "$SRC/PortalAuthenticator" "$DEST/"
cp -r "$SRC/AuthenticatorTriggers" "$DEST/"
cp "$SRC/probe.sh" "$SRC/authenticate.sh" "$DEST/"
chmod -R a+rX "$DEST"
find "$DEST" -name '*.sh' -exec chmod +x {} +

# 2. 生成凭据配置模板（root-only）
if [ ! -f "$CONF" ]; then
cat > "$CONF" <<'EOF'
# H3C 校园网认证配置（root-only 0600，勿泄露）
# 刷机后按实机页面填写；H3C 页面结构待实机抓取后由用户提供
PORTAL_URL=https://portal.example.edu.cn/    # 登录页 URL（HTTPS 优先；自签证书 curl 需 -k）
PORTAL_USER=
PORTAL_PASS=
PORTAL_MODE=h3c-template                    # h3c-template | generic-form | record-replay
# --- 认证器参数（按实机页面填） ---
USER_FIELD=userId                            # 用户名输入框 name（H3C 常见 userId/username）
PASS_FIELD=password                          # 密码输入框 name
H3C_URL=                                     # 认证 POST URL（空=用 PORTAL_URL）
CHALLENGE_CMD=                               # 挑战码命令（有 JS 挑战机制时填，输出挑战值到 stdout）
SUCCESS_MARKER='success|成功|欢迎'            # 认证成功标记（正则）
DUMP=0                                       # 调试：1=抓登录页存 /tmp 供分析
# --- 触发器参数 ---
TRIGGER=keepalive-daemon                     # keepalive-daemon(5min) | lazy(30min) | manual
KEEPALIVE_INTERVAL=300
LAZY_INTERVAL=1800
RETRIES=3
# --- 探测 ---
PROBE_URL=http://example.edu.cn/             # 连通性探针（被重定向到门户/返回登录页=掉线）
PORTAL_HOST=portal                           # 门户 URL 特征关键字（判定重定向到门户）
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
EOF
chmod 600 "$CONF"
fi

# 3. 注册 init.d（触发器按 TRIGGER 配置选择模式）
cat > /etc/init.d/portal-keepalive <<'EOF'
#!/bin/sh /etc/rc.common
START=99
STOP=1
start() {
  [ -f /etc/portal.conf ] || return 0
  . /etc/portal.conf 2>/dev/null
  MODE=${TRIGGER:-keepalive-daemon}
  RUN=/etc/portal/AuthenticatorTriggers/$MODE/run.sh
  [ -x "$RUN" ] || return 0
  logger -t portal-keepalive "starting trigger: $MODE"
  "$RUN" &
}
stop() {
  killall portal-keepalive 2>/dev/null || true
  pkill -f 'AuthenticatorTriggers/' 2>/dev/null || true
}
EOF
chmod +x /etc/init.d/portal-keepalive
/etc/init.d/portal-keepalive enable

echo "[portal] installed. 编辑 /etc/portal.conf（root-only）填真实凭据后: /etc/init.d/portal-keepalive start"
echo "        调试: DUMP=1 跑 /etc/portal/PortalAuthenticator/h3c-template/authenticate.sh"
echo "        摘除: hdd-modules/portal/remove.sh"
