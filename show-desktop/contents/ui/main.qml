import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "plugin"

PlasmoidItem {
    id: root

    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // 只用 Plasma 自带的 applet 提示：标题“显示桌面”，副标题提示下一次点击的结果
    toolTipMainText: i18n("显示桌面")
    toolTipSubText: showDesktop.showingDesktop ? i18n("恢复窗口") : i18n("显示桌面")

    ShowDesktop {
        id: showDesktop
    }


    compactRepresentation: Item {
        implicitWidth: 22
        implicitHeight: 22

        // 竖条比 applet 本身高一些，尽量接近整个面板高度
        readonly property int barHeight: Math.round(implicitHeight * 1.6)

        Rectangle {
            id: stripArea
            x: root.verticalPanel ? Math.round((parent.width - width) / 2) : parent.width - 8
            y: root.verticalPanel ? Math.round((parent.height - height) / 2) : Math.round((parent.height - height) / 2)
            width: root.verticalPanel ? parent.width : 8
            height: barHeight
            radius: 3
            color: stripMouse.containsMouse
                   ? Qt.alpha(Kirigami.Theme.highlightColor, 0.35)
                   : "transparent"
        }

        // 左侧（竖向面板为上侧）分隔线，随竖条一起加长
        Rectangle {
            x: root.verticalPanel ? Math.round((parent.width - width) / 2) : parent.width - 8
            y: root.verticalPanel ? Math.round((parent.height - height) / 2) : Math.round((parent.height - barHeight) / 2)
            width: root.verticalPanel ? parent.width : 1
            height: root.verticalPanel ? 1 : barHeight
            color: Kirigami.Theme.textColor
            opacity: 0.25
        }

        MouseArea {
            id: stripMouse
            // 只有分隔线右侧/下侧的窄条属于本控件，线左侧不响应点击
            x: root.verticalPanel ? 0 : parent.width - 8
            y: root.verticalPanel ? Math.round((parent.height - height) / 2) : Math.round((parent.height - height) / 2)
            width: root.verticalPanel ? parent.width : 8
            height: barHeight
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: showDesktop.toggle()
        }
    }

    fullRepresentation: Item {
        implicitWidth: root.verticalPanel ? Math.round(Kirigami.Units.gridUnit * 2) : 10
        implicitHeight: root.verticalPanel ? 10 : Math.round(Kirigami.Units.gridUnit * 2)
    }
}
