# PortalAuthenticator — 校园网认证器模块集

登录 Web 认证的**执行器**（实际发出认证请求的部分）。三类形态全做，模块化：
`触发器`（AuthenticatorTriggers/）只决定"何时调认证器"，认证器负责"怎么登"。

```
PortalAuthenticator/
├── generic-form/    (A) 通用表单解析器：抓登录页 → 自动定位 user/pass 字段 → POST → 按成功标记验证
├── record-replay/   (B) 录制重放：浏览器抓一次完整登录流程照着重放
└── h3c-template/    (C) H3C 模板 —— 学校网关已确认为 H3C，优先调优的主模块
```

## 通用接口约定（待票 4 规格锁定后填充）

- 每个认证器提供同一入口（如 `authenticate.sh`）：读取 `/etc/portal.conf`（root-only）→ 执行登录 → 退出码表示成败。
- 配置驱动：URL、字段名、UA、成功标记全部在配置文件，调参不重编译。
- UA：内置真实 Chrome UA，可配置（"UA 正常"）。
- 传输安全：门户支持 HTTPS 则走 HTTPS（TLS ECDHE 即一次性密钥，自签证书用 `--insecure`）；纯 HTTP 则遵循 H3C 页面协议内置机制。**不自创加密**（学校服务器不认）。

## 待刷机后填充（用户提供）

- 门户 URL、页面结构（字段名/挑战码机制）、证书情况
