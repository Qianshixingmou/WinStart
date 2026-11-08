import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: root

    property alias cfg_popupHeight: heightSpin.value
    property alias cfg_listMode: modeCombo.currentIndex
    property alias cfg_showRecent: recentCheck.checked
    property alias cfg_railVisible: railCheck.checked
    property alias cfg_tileUnit: tileUnitSpin.value
    // 逗号分隔的隐藏文件夹名
    property string cfg_hiddenPlaces: ""

    readonly property var placeNames: [
        i18n("主文件夹"),
        i18n("桌面"),
        i18n("文档"),
        i18n("下载"),
        i18n("音乐"),
        i18n("图片"),
        i18n("视频"),
        i18n("回收站")
    ]

    function hiddenList() {
        return String(cfg_hiddenPlaces || "").split(",").filter(s => s.length > 0)
    }

    function placeShown(name) {
        return hiddenList().indexOf(name) < 0
    }

    function setPlaceShown(name, shown) {
        let list = hiddenList().filter(s => s !== name)
        if (!shown) {
            list.push(name)
        }
        cfg_hiddenPlaces = list.join(",")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.gridUnit

        Kirigami.FormLayout {
            Layout.fillWidth: true

            QQC2.ComboBox {
                id: modeCombo
                Kirigami.FormData.label: i18n("应用列表显示方式：")
                model: [i18n("字母排序（A–Z）"), i18n("系统分类（XDG 菜单）")]
            }

            QQC2.CheckBox {
                id: recentCheck
                text: i18n("显示“最近使用”")
            }

            QQC2.CheckBox {
                id: railCheck
                text: i18n("始终显示左侧文件夹栏")
            }

            ColumnLayout {
                Kirigami.FormData.label: i18n("显示的文件夹：")

                Repeater {
                    model: root.placeNames

                    QQC2.CheckBox {
                        text: modelData
                        checked: root.placeShown(modelData)
                        onToggled: root.setPlaceShown(modelData, checked)
                    }
                }
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

        Item {
            Layout.fillHeight: true
        }
    }
}
