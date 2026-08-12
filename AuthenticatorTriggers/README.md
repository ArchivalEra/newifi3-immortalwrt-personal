# AuthenticatorTriggers — 认证触发器（保活模式）

决定**何时**调用认证器（PortalAuthenticator/）的调度器。三种模式全做，可配置切换，共用同一套认证器接口。

```
AuthenticatorTriggers/
├── keepalive-daemon/   (a) 常驻保活：每 5 分钟探测（间隔可配），被踢/过期自动重登
├── lazy/               (b) 慵懒：探测间隔 15–30 分钟，断网才重登
└── manual/             (c) 手动 / 掉线才处理
```

- 掉线判定：可配置连通性探针 URL（默认校内稳定页面），响应被重定向到门户 = 掉线
- 统一由 `init.d` 脚本管理，选择模式写入配置（如 `/etc/portal-trigger.conf`）

状态：骨架占位，待票 4 规格锁定后填充。
