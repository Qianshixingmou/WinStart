import QtQuick

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// 侧栏/底栏共用的电源菜单：样式和宽度一致，只构建可见项
PlasmaComponents3.Menu {
    id: menu

    property var systemModel: null
    property var hiddenActions: []
    property int preferredWidth: 180
    property var items: []

    width: preferredWidth

    function refresh() {
        const out = []
        if (systemModel) {
            for (let i = 0; i < systemModel.count; ++i) {
                const idx = systemModel.index(i, 0)
                const label = String(idx.data(Qt.DisplayRole) ?? "")
                if (hiddenActions.indexOf(label) >= 0) {
                    continue
                }
                out.push({
                    row: i,
                    label: label,
                    icon: String(idx.data(Qt.DecorationRole) ?? "")
                })
            }
        }
        menu.items = out
    }

    function estimatedHeight() {
        return Math.max(1, menu.items.length) * 34 + 8
    }

    function openRight(anchor) {
        refresh()
        const p = anchor.mapToItem(null, 0, 0)
        let x = p.x + anchor.width + Kirigami.Units.smallSpacing
        if (x + width > Screen.desktopAvailableWidth) {
            x = Math.max(0, p.x - width - Kirigami.Units.smallSpacing)
        }
        let y = p.y + anchor.height - estimatedHeight()
        if (y < 0) {
            y = 0
        }
        menu.x = x
        menu.y = y
        menu.open()
    }

    function openAbove(anchor) {
        refresh()
        const p = anchor.mapToItem(null, 0, 0)
        const x = Math.max(0, Math.min(p.x + anchor.width - width,
                                       Screen.desktopAvailableWidth - width))
        let y = p.y - estimatedHeight() - Kirigami.Units.smallSpacing
        if (y < 0) {
            y = 0
        }
        menu.x = x
        menu.y = y
        menu.open()
    }

    Repeater {
        model: menu.items

        PlasmaComponents3.MenuItem {
            text: modelData.label
            icon.name: modelData.icon
            onTriggered: {
                if (menu.systemModel) {
                    menu.systemModel.trigger(modelData.row, "", null)
                }
            }
        }
    }
}
