# portal — 校园网认证模块（寄生模块，可摘除）

**用途**：H3C 校园网 Web 认证 + 保活。启用前系统是出厂路由器（无认证逻辑）；`remove.sh` 摘除即回退。

## 内容

```
portal/
├── PortalAuthenticator/     认证执行器：A 通用表单 / B 录制重放 / C H3C 模板（学校网关已确认 H3C）
├── AuthenticatorTriggers/   触发器：a 常驻保活(5min) / b 慵懒(15-30min) / c 手动 —— 共用认证器接口
├── install.sh               部署到系统 + 注册 init.d
└── remove.sh                卸载，回退出厂
```

## 安装流程（install.sh 做什么）

1. 部署 `PortalAuthenticator/` + `AuthenticatorTriggers/` → `/etc/portal/`（认证器 + 触发器）
2. 生成 `/etc/portal.conf` 模板（root-only 0600）：URL / 用户名 / 密码 / UA / 探针 URL / 成功标记 —— **刷机后填真实值**（H3C 页面结构待实机抓取）
3. 注册 `/etc/init.d/portal-keepalive`（触发器模式可配置：keepalive-daemon / lazy / manual）
4. 不写死任何认证逻辑进系统默认 —— 全部模块内

## 摘除（remove.sh）

删除 `/etc/portal/`、`/etc/portal.conf`、init.d 脚本 → 系统回到出厂路由器。

## 安全（票 3 决议）

- 凭据文件 root-only 0600；进程不落密码明文日志
- 传输走 HTTPS（TLS ECDHE=一次性密钥，自签证书 `--insecure`）或 H3C 协议内置机制，**不自创加密**
- UA 内置真实 Chrome UA 可配置（"UA 正常"）
