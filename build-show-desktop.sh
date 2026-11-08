#!/usr/bin/env bash
# 编译 show-desktop 的 C++ QML 插件，并把 plasmoid 安装到 ~/.local/share/plasma/plasmoids
set -euo pipefail
cd "$(dirname "$0")"

# 如果当前 shell 里没有 Qt6 开发环境，自动进入项目的 nix-shell
if ! command -v cmake >/dev/null 2>&1 || ! pkg-config --exists Qt6Qml 2>/dev/null; then
    exec nix-shell --run "bash '$PWD/$(basename "$0")'"
fi

cmake -S show-desktop/plugin -B show-desktop/build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build show-desktop/build
cp show-desktop/build/libqianshi_showdesktop.so show-desktop/contents/ui/plugin/

if ! kpackagetool6 --type Plasma/Applet --upgrade show-desktop 2>/dev/null; then
    kpackagetool6 --type Plasma/Applet --install show-desktop
fi

echo "已安装 org.qianshi.showdesktop"
echo "在面板“添加小组件”里搜索“显示桌面（细条）”即可添加。"
