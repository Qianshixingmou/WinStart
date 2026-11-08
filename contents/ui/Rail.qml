import QtQuick
import QtQuick.Layouts
import QtQml.Models

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
    property var powerMenu: null

    signal closeRequested()
    signal pinPlaceRequested(string url, string label)

    property string menuPlaceUrl: ""
    property string menuPlaceLabel: ""

    KCoreAddons.KUser {
        id: kuser
    }

    Metrics {
        id: metrics
    }

    readonly property var hiddenNames: String(Plasmoid.configuration.hiddenPlaces || "").split(",").filter(s => s.length > 0)
    readonly property var hiddenPower: String(Plasmoid.configuration.hiddenPowerActions || "").split(",").filter(s => s.length > 0)

    function powerVisible(label) {
        return hiddenPower.indexOf(String(label ?? "")) < 0
    }
    // KDE 默认把“视频”标记为隐藏，places 模型里没有它，这里在启用时补一条
    readonly property bool showVideos: hiddenNames.indexOf(i18n("视频")) < 0
    readonly property string videosUrl: "file:///home/" + kuser.loginName + "/Videos"

    ListModel {
        id: placeEntries
    }

    function placeIcon(label) {
        if (label === i18n("主文件夹")) return "user-home"
        if (label === i18n("桌面")) return "folder-desktop"
        if (label === i18n("文档")) return "folder-documents"
        if (label === i18n("下载")) return "folder-downloads"
        if (label === i18n("音乐")) return "folder-music"
        if (label === i18n("图片")) return "folder-pictures"
        if (label === i18n("视频")) return "folder-videos"
        if (label === i18n("回收站")) return "user-trash"
        return "folder"
    }

    function rebuildPlaceEntries() {
        placeEntries.clear()
        if (!rail.placesModel) {
            return
        }
        const n = rail.placesModel.rowCount()
        let videosDone = false
        for (let i = 0; i < n; ++i) {
            const idx = rail.placesModel.index(i, 0)
            const label = String(idx.data(Qt.DisplayRole) ?? "")
            const url = String(idx.data(Qt.UserRole + 3) ?? "")
            if (label.length === 0 || url.length === 0) {
                continue
            }
            if (label.indexOf("KRunner") >= 0) {
                continue
            }
            if (rail.hiddenNames.indexOf(label) >= 0) {
                continue
            }
            if (!videosDone && rail.showVideos && label === i18n("回收站")) {
                placeEntries.append({ label: i18n("视频"), url: rail.videosUrl, row: -1, icon: "folder-videos" })
                videosDone = true
            }
            placeEntries.append({ label: label, url: url, row: i, icon: placeIcon(label) })
        }
        if (!videosDone && rail.showVideos) {
            placeEntries.append({ label: i18n("视频"), url: rail.videosUrl, row: -1, icon: "folder-videos" })
        }
    }

    Component.onCompleted: rebuildPlaceEntries()

    Connections {
        target: rail.placesModel
        ignoreUnknownSignals: true
        function onCountChanged() {
            rail.rebuildPlaceEntries()
        }
    }

    function openPowerMenu() {
        if (rail.powerMenu) {
            rail.powerMenu.openRight(powerButton)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: metrics.railTopMargin
        anchors.bottomMargin: metrics.railBottomMargin
        spacing: metrics.itemSpacing

        // 用户头像（圆形）
        KirigamiComponents.AvatarButton {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: metrics.avatarSize
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

        // 文件夹快捷入口（和头像拉开一点距离）
        ListView {
            id: placesView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Math.round(Kirigami.Units.gridUnit * 0.5)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: placeEntries

            delegate: PlasmaComponents3.ItemDelegate {
                width: ListView.view.width
                height: Math.round(Kirigami.Units.gridUnit * 2.6)
                leftPadding: 2
                rightPadding: 2
                topPadding: 2
                bottomPadding: 2

                // 图标一行、文件名一行，纵向排列
                contentItem: ColumnLayout {
                    spacing: 2

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: model.icon
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        text: model.label
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        horizontalAlignment: Text.AlignHCenter
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        rail.menuPlaceUrl = model.url
                        rail.menuPlaceLabel = model.label
                        rail.placeMenu.popup()
                    }
                }

                onClicked: {
                    if (model.row >= 0) {
                        if (rail.placesModel && rail.placesModel.trigger(model.row, "", null)) {
                            rail.closeRequested()
                        }
                    } else {
                        Qt.openUrlExternally(model.url)
                        rail.closeRequested()
                    }
                }

                PlasmaComponents3.ToolTip.text: model.url
                PlasmaComponents3.ToolTip.visible: hovered
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

}
