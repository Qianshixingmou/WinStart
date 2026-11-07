import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents
import org.kde.coreaddons as KCoreAddons
import org.kde.kcmutils as KCM

Item {
    id: rail

    property var applet: null
    property var placesModel: null
    property var systemModel: null

    signal closeRequested()
    signal pinPlaceRequested(string url, string label)

    property string menuPlaceUrl: ""
    property string menuPlaceLabel: ""

    KCoreAddons.KUser {
        id: kuser
    }

    function openPowerMenu() {
        const p = powerButton.mapToItem(null, 0, 0)
        const w = powerMenu.implicitWidth
        const h = powerMenu.implicitHeight
        // 弹在按钮右侧，避免盖住按钮本身
        let x = p.x + powerButton.width + Kirigami.Units.smallSpacing
        if (x + w > Screen.desktopAvailableWidth) {
            x = Math.max(0, p.x - w - Kirigami.Units.smallSpacing)
        }
        let y = p.y + powerButton.height - h
        if (y < 0) {
            y = 0
        }
        powerMenu.x = x
        powerMenu.y = y
        powerMenu.open()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: Math.round(Kirigami.Units.gridUnit * 0.7)
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        // 用户头像（圆形）
        KirigamiComponents.AvatarButton {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.round(Kirigami.Units.gridUnit * 1.9)
            implicitHeight: implicitWidth

            text: i18n("账户设置")
            name: kuser.fullName || kuser.loginName
            source: kuser.faceIconUrl
            cache: false

            onClicked: {
                KCM.KCMLauncher.openSystemSettings("kcm_users")
                rail.closeRequested()
            }
        }

        // 文件夹快捷入口
        ListView {
            id: placesView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: rail.placesModel

            delegate: PlasmaComponents3.ItemDelegate {
                id: placeItem

                readonly property bool isRecent: String(model.url ?? "").startsWith("recent")
                // 跳过“运行命令…”这类没有 URL 的条目
                readonly property bool hiddenItem: isRecent || String(model.url ?? "").length === 0

                width: ListView.view.width
                height: hiddenItem ? 0 : Math.round(Kirigami.Units.gridUnit * 1.9)
                visible: !hiddenItem
                leftPadding: 4
                rightPadding: 2
                spacing: 4

                text: model.display

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        source: model.decoration ?? ""
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: placeItem.text
                        elide: Text.ElideRight
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        rail.menuPlaceUrl = String(model.url ?? "")
                        rail.menuPlaceLabel = String(model.display ?? "")
                        rail.placeMenu.popup()
                    }
                }

                onClicked: {
                    if (rail.placesModel && rail.placesModel.trigger(index, "", null)) {
                        rail.closeRequested()
                    }
                }

                PlasmaComponents3.ToolTip.text: String(model.url ?? "")
                PlasmaComponents3.ToolTip.visible: hovered && !hiddenItem
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        // 设置 / 电源
        PlasmaComponents3.ToolButton {
            Layout.alignment: Qt.AlignHCenter
            icon.name: "settings-configure"
            display: PlasmaComponents3.AbstractButton.IconOnly
            onClicked: {
                KCM.KCMLauncher.openSystemSettings("")
                rail.closeRequested()
            }
            PlasmaComponents3.ToolTip.text: i18n("系统设置")
            PlasmaComponents3.ToolTip.visible: hovered
            PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        PlasmaComponents3.ToolButton {
            id: powerButton
            Layout.alignment: Qt.AlignHCenter
            icon.name: "system-shutdown"
            display: PlasmaComponents3.AbstractButton.IconOnly
            onClicked: rail.openPowerMenu()
            PlasmaComponents3.ToolTip.text: i18n("电源")
            PlasmaComponents3.ToolTip.visible: hovered
            PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }

    PlasmaComponents3.Menu {
        id: placeMenu

        PlasmaComponents3.MenuItem {
            text: i18n("固定到开始屏幕")
            icon.name: "bookmark-new"
            onTriggered: rail.pinPlaceRequested(rail.menuPlaceUrl, rail.menuPlaceLabel)
        }
    }

    PlasmaComponents3.Menu {
        id: powerMenu

        Repeater {
            model: rail.systemModel

            PlasmaComponents3.MenuItem {
                text: model.display
                icon.name: model.decoration
                onTriggered: {
                    rail.systemModel.trigger(index, "", null)
                    rail.closeRequested()
                }
            }
        }
    }
}
