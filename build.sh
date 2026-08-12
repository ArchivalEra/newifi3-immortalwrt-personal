#!/bin/sh
# 离线构建 Newifi3 固件（ImmortalWrt 25.12.1, ramips/mt7621, d-team_newifi-d2）
# 依赖：/mnt/hdd/build-staff/ 下 IB 已解压 + pool 已镜像 + repositories 已补丁 file://
# 用法：./build.sh
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
IB=/mnt/hdd/build-staff/immortalwrt-imagebuilder-25.12.1-ramips-mt7621.Linux-x86_64
[ -d "$IB" ] || { echo "IB 目录不存在: $IB"; exit 1; }

cd "$IB"

# 出厂基础设施包（flash 内）：SSH + 挂盘引导 + 认证依赖 + 编辑器
# 注：micro 为 Go 静态二进制，若超 IMAGE_SIZE 需从列表移除（改入 ext4）
PACKAGES="dropbear curl block-mount blockd fdisk e2fsprogs xfsprogs nano micro"

echo "==> make image (PACKAGES=$PACKAGES, FILES=$ROOT/files)"
make image PROFILE=d-team_newifi-d2 \
  PACKAGES="$PACKAGES" \
  FILES="$ROOT/files"

echo "==> 产物:"
ls -lh "$IB"/bin/targets/ramips/mt7621/*sysupgrade*.bin 2>/dev/null || true
