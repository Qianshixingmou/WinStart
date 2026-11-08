import QtQuick

import org.kde.plasma.configuration

// Plasma 的小组件配置入口：把页面拆到 config/ConfigGeneral.qml
ConfigModel {
    ConfigCategory {
        name: i18n("常规")
        icon: "preferences-system"
        source: "config/ConfigGeneral.qml"
    }
}
