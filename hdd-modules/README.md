# hdd-modules — 刷机后装到硬盘的扩展模块集

与 flash 固件**解耦**的扩展模块（不烧 32M flash）。刷机 + ext4 挂载后，把本目录拷到硬盘（如 `/mnt/data/hdd-modules/` 或 extroot 的 `/etc/` 下），按需启用。

```
hdd-modules/
└── wan6/       IPv6 开关模块：OFF（默认）/ A 双栈 / B 仅 WAN —— 到校实测公网 v6 后决定
```

后续模块（LuCI 安装脚本、杂项）追加在此。
