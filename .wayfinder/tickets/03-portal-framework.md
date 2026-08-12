---
title: Portal 认证框架形态
type: grilling
label: wayfinder:grilling
status: open
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

（grilling 对话完成时记录）
