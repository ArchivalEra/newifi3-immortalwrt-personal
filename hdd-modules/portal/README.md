# portal — 校园网认证模块（寄生模块，可摘除）

**用途**：H3C 校园网 Web 认证 + 保活。`install.sh` 部署，`remove.sh` 摘除即回退出厂路由器。

## 结构（install.sh 部署到 /etc/portal/）

```
/etc/portal/
├── probe.sh                  连通性探测（探针被重定向到门户/返回登录页 → 掉线）
├── authenticate.sh           认证分发器（按 PORTAL_MODE 调对应认证器）
├── PortalAuthenticator/
│   ├── generic-form/         (A) 通用表单解析：抓登录页→解析字段→POST→成功标记验证
│   ├── record-replay/        (B) 录制重放：浏览器 Copy as cURL → capture 文件重放
│   └── h3c-template/         (C) H3C 模板（主模块）：字段/挑战码配置驱动，DUMP 调试
└── AuthenticatorTriggers/
    ├── keepalive-daemon/     (a) 常驻保活：每 KEEPALIVE_INTERVAL(默认300s) 探测，掉线自动重登
    ├── lazy/                 (b) 慵懒：LAZY_INTERVAL(默认1800s)，断网才重登
    └── manual/               (c) 手动：跑一次 探测+重登（可配 cron）
```

## 接口约定

- 认证器入口统一：`/etc/portal/PortalAuthenticator/<mode>/authenticate.sh` → exit 0=成功 / 1=失败 / 2=未配置
- 触发器统一：`/etc/portal/AuthenticatorTriggers/<mode>/run.sh`（keepalive/lazy 为循环常驻，manual 单次）
- 全部配置在 `/etc/portal.conf`（root-only 0600），调参不重编译

## 使用流程（刷机后）

1. `install.sh` → 生成 `/etc/portal.conf` 模板
2. `DUMP=1` 跑 h3c-template 认证器 → 抓登录页存 `/tmp/portal_dump.html` → 填 URL/字段/挑战码
3. `TRIGGER=keepalive-daemon`（或 lazy/manual）→ `service portal-keepalive start`
4. 看日志：`logread | grep portal-`
5. 换模式：改 `/etc/portal.conf` 的 TRIGGER → `service portal-keepalive restart`

## 安全（票 3 决议）

- 凭据文件 root-only 0600；进程不落密码明文日志
- 传输走 HTTPS（TLS ECDHE=一次性密钥，自签证书 `--insecure`）或 H3C 协议内置机制，**不自创加密**
- UA 内置真实 Chrome UA 可配置（"UA 正常"）
