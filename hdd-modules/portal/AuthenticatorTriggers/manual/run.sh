#!/bin/sh
# (c) 手动模式：执行一次"探测 + 掉线则重登"（可配 cron 或手动调用；不加壳循环）
# 手动: /etc/portal/AuthenticatorTriggers/manual/run.sh

if /etc/portal/probe.sh; then
  echo "online (nothing to do)"
  exit 0
fi
/etc/portal/authenticate.sh
