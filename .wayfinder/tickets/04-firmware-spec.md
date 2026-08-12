---
title: 固件构成规格确认
type: grilling
label: wayfinder:grilling
status: open
blocked-by: [02-accel-vs-cloak.md]
blocks: []
parent: ../map.md
---

## Question

固件构成全部细节锁定（票 2 解出后过一遍）：

- 包列表逐项确认（含 WiFi 备用组件、USB/XFS/ext4、SFE 是否入包）
- network/dhcp/firewall/fstab/wireless 配置细节（flowtable 语法、extroot、swapfile、伪装规则）
- build.sh 与 README 形态；产物验证清单（认证日志、offload 状态、硬盘挂载、TTL 检查）

## Resolution

（grilling 对话完成时记录；本票关闭即规格锁定，可交普通会话构建）
