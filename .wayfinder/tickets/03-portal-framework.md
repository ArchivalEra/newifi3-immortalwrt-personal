---
title: Portal 认证框架形态
type: grilling
label: wayfinder:grilling
status: closed
blocked-by: []
blocks: []
parent: ../map.md
---

## Question

学校自建门户（URL/字段未知）的认证自动化框架选什么形态？

- 通用表单解析（抓登录页 → 自动解析 user/pass 字段 → POST → 探测验证）vs 模板库 vs 学习模式
- 心跳/保活策略与重连频率
- UA 处理（内置真实 Chrome UA，可配置 —— 即"UA 正常"）
- 收集门户信息的流程（刷机后用户提供登录页 URL/页面结构，配置驱动调参、不重编译）

## Resolution

grilling 于 2026-08-12 完成。用户确认：

1. **网关品牌 = H3C**（用户曾查看认证网关，确认为华三 H3C）。框架形态：**A/B/C 三类全做、模块化**，不排序不深挖（URL/字段细节留待刷机后按 H3C 协议调试），目录：
   ```
   newifi3/PortalAuthenticator/
     generic-form/    (A) 通用表单解析器：抓登录页→解析 user/pass 字段→POST→按成功标记验证
     record-replay/   (B) 录制重放：浏览器抓一次完整登录流程照着重放
     h3c-template/    (C) H3C 模板：学校已确认 H3C 网关 → 优先调优的主模块
   ```
2. **保活触发模式 a/b/c 全做**，目录 `newifi3/AuthenticatorTriggers/`：
   - `keepalive-daemon/`（a）常驻保活，探测间隔可配（默认 5min）
   - `lazy/`（b）慵懒模式，探测间隔 15–30min，断网才重登
   - `manual/`（c）手动 / 掉线才处理
   - 三模式共用同一套认证器接口（触发器只管"何时调认证器"）
3. **传输安全（"那一秒"安全）**：MT7621 无 AES 硬件引擎（MIPS 1004Kc 无 crypto 协处理器；"硬件加速吃满"指数据面 flow offload，与加解密无关），但登录为几 KB 小请求，软件 AES-256-GCM/ChaCha20 毫秒级完成，无性能问题。加密是双端协议 → 学校 H3C 服务器不认自定义加密，正解：
   - 门户支持 HTTPS → 登录走 HTTPS（TLS ECDHE 每次握手即"即时生成一次性密钥"的标准实现；校园网自签证书 → curl --insecure）
   - 门户纯 HTTP → 按 H3C 网页协议内置机制处理密码字段（挑战码/JS 编码等），不破坏兼容
   - 本地：凭据文件 root-only 0600、进程不写密码明文日志
4. **UA**：登录请求内置真实 Chrome UA，可配置（即"UA 正常"）。
5. **探测/掉线判定**：可配置连通性探针 URL（默认校内稳定页面），被重定向到门户即判定掉线 → 触发重登。

待刷机后由用户提供：门户 URL、页面结构（字段名/挑战机制）、证书情况 —— 全部配置驱动调参，不重编译。
