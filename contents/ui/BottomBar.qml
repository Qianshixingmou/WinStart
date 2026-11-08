import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents
import org.kde.kcmutils as KCM
import org.kde.coreaddons as KCoreAddons

// 侧栏收起时整条的底部栏：头像 + 文件夹 + 设置/电源
RowLayout {
    id: bar

    property var placesModel: null
    property var systemModel: null
    property var powerMenu: null

    readonly property var hiddenPower: String(Plasmoid.configuration.hiddenPowerActions || "").split(",").filter(s => s.length > 0)

    function powerVisible(label) {
        return hiddenPower.indexOf(String(label ?? "")) < 0
    }

    signal closeRequested()

    KCoreAddons.KUser {
        id: kuser
    }

    Metrics {
        id: metrics
    }

    spacing: metrics.itemSpacing

    KirigamiComponents.AvatarButton {
        Layout.leftMargin: metrics.edgeMargin
        implicitWidth: metrics.avatarSize
        implicitHeight: implicitWidth

        text: i18n("账户设置")
        name: kuser.fullName || kuser.loginName
        source: kuser.faceIconUrl
        cache: false

        onClicked: {
            KCM.KCMLauncher.openSystemSettings("kcm_users")
            bar.closeRequested()
        }
    }

    PlacesRow {
        Layout.fillWidth: true
        Layout.fillHeight: true
        placesModel: bar.placesModel
        onCloseRequested: bar.closeRequested()
    }

    PlasmaComponents3.ToolButton {
        icon.name: "settings-configure"
        display: PlasmaComponents3.AbstractButton.IconOnly
        onClicked: {
            KCM.KCMLauncher.openSystemSettings("")
            bar.closeRequested()
        }
        PlasmaComponents3.ToolTip.text: i18n("系统设置")
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    PlasmaComponents3.ToolButton {
        id: powerButton
        icon.name: "system-shutdown"
        display: PlasmaComponents3.AbstractButton.IconOnly
        Layout.rightMargin: metrics.edgeMargin
        onClicked: {
            if (bar.powerMenu) {
                bar.powerMenu.openAbove(powerButton)
            }
        }
        PlasmaComponents3.ToolTip.text: i18n("电源")
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

}
