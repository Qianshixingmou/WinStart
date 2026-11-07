import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.kcmutils as KCM

RowLayout {
    id: row

    property var systemModel: null

    signal closeRequested()

    KCoreAddons.KUser {
        id: kuser
    }

    spacing: Kirigami.Units.smallSpacing

    Item {
        implicitWidth: Math.round(Kirigami.Units.gridUnit * 1.8)
        implicitHeight: implicitWidth

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Kirigami.Theme.alternateBackgroundColor
            clip: true

            Image {
                id: faceImage
                anchors.fill: parent
                source: kuser.faceIconUrl
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Math.round(parent.width * 0.6)
                height: width
                source: "user-identity"
                visible: !faceImage.visible
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                KCM.KCMLauncher.openSystemSettings("kcm_users")
                row.closeRequested()
            }
        }
    }

    Item {
        Layout.fillWidth: true
    }

    PlasmaComponents3.ToolButton {
        icon.name: "settings-configure"
        display: PlasmaComponents3.AbstractButton.IconOnly
        onClicked: {
            KCM.KCMLauncher.openSystemSettings("")
            row.closeRequested()
        }
        PlasmaComponents3.ToolTip.text: i18n("系统设置")
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    PlasmaComponents3.ToolButton {
        id: powerButton
        icon.name: "system-shutdown"
        display: PlasmaComponents3.AbstractButton.IconOnly
        onClicked: {
            const p = powerButton.mapToItem(null, 0, 0)
            powerMenu.x = Math.max(0, p.x + powerButton.width - powerMenu.implicitWidth)
            powerMenu.y = Math.max(0, p.y - powerMenu.implicitHeight)
            powerMenu.open()
        }
        PlasmaComponents3.ToolTip.text: i18n("电源")
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    PlasmaComponents3.Menu {
        id: powerMenu

        Repeater {
            model: row.systemModel

            PlasmaComponents3.MenuItem {
                text: model.display
                icon.name: model.decoration
                onTriggered: {
                    row.systemModel.trigger(index, "", null)
                    row.closeRequested()
                }
            }
        }
    }
}
