#!/bin/sh
# (a) 常驻保活：每 KEEPALIVE_INTERVAL 秒探测一次；掉线自动重登（失败重试 RETRIES 次）
. /etc/portal.conf
INTERVAL=${KEEPALIVE_INTERVAL:-300}
RETRIES=${RETRIES:-3}

logger -t portal-keepalive "start (interval=${INTERVAL}s)"
while true; do
  if /etc/portal/probe.sh; then
    logger -t portal-keepalive "online"
  else
    logger -t portal-keepalive "offline -> re-auth"
    i=0
    while [ "$i" -lt "$RETRIES" ]; do
      if /etc/portal/authenticate.sh; then
        logger -t portal-keepalive "auth ok"
        break
      fi
      i=$((i+1)); sleep 5
    done
    [ "$i" -ge "$RETRIES" ] && logger -t portal-keepalive "auth FAILED after ${RETRIES} tries"
  fi
  sleep "$INTERVAL"
done
