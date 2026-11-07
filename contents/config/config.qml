import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_popupHeight: heightSpin.value
    property alias cfg_listMode: modeCombo.currentIndex
    property alias cfg_showRecent: recentCheck.checked
    property alias cfg_railVisible: railCheck.checked
    property alias cfg_tileUnit: tileUnitSpin.value

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: modeCombo
            Kirigami.FormData.label: i18n("应用列表显示方式：")
            model: [i18n("字母排序（A–Z）"), i18n("自定义分类")]
        }

        QQC2.CheckBox {
            id: recentCheck
            text: i18n("显示“最近使用”")
        }

        QQC2.CheckBox {
            id: railCheck
            text: i18n("始终显示左侧文件夹栏")
        }

        QQC2.SpinBox {
            id: tileUnitSpin
            Kirigami.FormData.label: i18n("磁贴大小：")
            from: 36
            to: 64
            stepSize: 4
        }

        QQC2.SpinBox {
            id: heightSpin
            Kirigami.FormData.label: i18n("弹窗高度：")
            from: 480
            to: 1000
            stepSize: 20
        }
    }
}
