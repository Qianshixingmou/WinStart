import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents
import org.kde.kcmutils as KCM
import org.kde.coreaddons as KCoreAddons

// 侧栏收起时整条的底部栏：头像 + 文件夹 + 设置/电源
RowLayout {
    id: bar

    property var placesModel: null
    property var systemModel: null

    signal closeRequested()

    KCoreAddons.KUser {
        id: kuser
    }

    spacing: Kirigami.Units.smallSpacing

    KirigamiComponents.AvatarButton {
        Layout.leftMargin: Kirigami.Units.smallSpacing
        implicitWidth: Math.round(Kirigami.Units.gridUnit * 1.6)
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
        Layout.rightMargin: Kirigami.Units.smallSpacing
        onClicked: powerMenu.openRelative()
        PlasmaComponents3.ToolTip.text: i18n("电源")
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    // 用 KDE 自己的 PlasmaExtras.Menu：相对按钮向上弹，自动避开按钮和窗口边缘
    PlasmaExtras.Menu {
        id: powerMenu
        visualParent: powerButton
        placement: PlasmaExtras.Menu.TopPosedRightAlignedPopup
    }

    Instantiator {
        model: bar.systemModel

        delegate: PlasmaExtras.MenuItem {
            text: model.display
            icon: model.decoration
            onClicked: {
                bar.systemModel.trigger(index, "", null)
                bar.closeRequested()
            }
        }

        onObjectAdded: (index, object) => powerMenu.addMenuItem(object)
        onObjectRemoved: (index, object) => powerMenu.removeMenuItem(object)
    }
}
