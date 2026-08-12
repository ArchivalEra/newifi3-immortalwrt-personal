#!/bin/sh
# (b) 慵懒模式：探测间隔拉长（默认 30min），只在断网时重登
. /etc/portal.conf
INTERVAL=${LAZY_INTERVAL:-1800}
RETRIES=${RETRIES:-3}

logger -t portal-lazy "start (interval=${INTERVAL}s)"
while true; do
  if /etc/portal/probe.sh; then
    logger -t portal-lazy "online"
  else
    logger -t portal-lazy "offline -> re-auth"
    i=0
    while [ "$i" -lt "$RETRIES" ]; do
      if /etc/portal/authenticate.sh; then
        logger -t portal-lazy "auth ok"
        break
      fi
      i=$((i+1)); sleep 5
    done
    [ "$i" -ge "$RETRIES" ] && logger -t portal-lazy "auth FAILED after ${RETRIES} tries"
  fi
  sleep "$INTERVAL"
done
