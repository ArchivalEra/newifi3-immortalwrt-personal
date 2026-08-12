# wan6 — IPv6 开关模块（默认 OFF）

校园网是否发公网 v6 **待实机确认**（记忆里不发，去学校实测有无升级）。因此 v6 做成三形态模块，**默认 OFF（伪装完整）**，实测拿到公网 v6 后再按需启用。

## 三形态

| 形态 | 脚本 | 行为 | 伪装影响 |
|---|---|---|---|
| **OFF**（默认） | `off.sh` | WAN/LAN 均无 IPv6 | 无（v4 单 IP NAT，伪装完整） |
| **A 双栈** | `a-dual-stack.sh` | WAN DHCPv6-PD + LAN 分发 v6 | v6 维度暴露多设备身份 |
| **B 仅 WAN** | `b-wan-only.sh` | 仅路由器 WAN 有 v6，LAN 不分发 | 无（LAN 仍纯 v4 单 IP NAT） |

## 用法（刷机 + ext4 挂载后）

```
scp -r hdd-modules/wan6/ root@192.168.50.1:/mnt/data/
# 或拷到 extroot 的 /etc/ 下
ssh root@192.168.50.1
chmod +x /mnt/data/wan6/*.sh
/mnt/data/wan6/off.sh          # 保持默认关
/mnt/data/wan6/a-dual-stack.sh # 学校发公网 v6 且要 LAN 双栈时
/mnt/data/wan6/b-wan-only.sh   # 只要路由器自己有 v6、LAN 保持伪装完整
```

## 注意

- `wan6` 接口的 `device` 需与 `network.wan` 对齐（`uci show network.wan` 实机确认，默认 eth0.2 按实机调整）
- 切换后 `network restart` 会短暂断网
- 决策标准：**WAN 拿到公网 v6 前缀**（非仅链路本地）才值得开；没有就保持 OFF，伪装最大
