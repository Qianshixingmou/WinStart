#!/usr/bin/env bash
# 升级本组件并强制 plasmashell 重新加载 QML（否则会继续用旧的组件缓存）
set -e
cd "$(dirname "$0")"

kpackagetool6 --type Plasma/Applet --upgrade .

# Plasma 会把编译后的 QML 缓存在这里；升级后必须清掉，否则组件还是旧界面
rm -rf "$HOME/.cache/plasmashell/qmlcache"

systemctl --user restart plasma-plasmashell.service
echo "已重装并重启 plasmashell。"
