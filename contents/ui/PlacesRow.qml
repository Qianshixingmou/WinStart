import QtQuick
import QtQuick.Layouts
import QtQml.Models

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons

// 侧栏收起时，文件夹快捷入口显示在磁贴下方的这一行
Item {
    id: row

    property var placesModel: null

    signal closeRequested()

    KCoreAddons.KUser {
        id: kuser
    }

    readonly property var hiddenNames: String(Plasmoid.configuration.hiddenPlaces || "").split(",").filter(s => s.length > 0)
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
        if (!row.placesModel) {
            return
        }
        const n = row.placesModel.rowCount()
        let videosDone = false
        for (let i = 0; i < n; ++i) {
            const idx = row.placesModel.index(i, 0)
            const label = String(idx.data(Qt.DisplayRole) ?? "")
            const url = String(idx.data(Qt.UserRole + 3) ?? "")
            if (label.length === 0 || url.length === 0) {
                continue
            }
            if (label.indexOf("KRunner") >= 0) {
                continue
            }
            if (row.hiddenNames.indexOf(label) >= 0) {
                continue
            }
            if (!videosDone && row.showVideos && label === i18n("回收站")) {
                placeEntries.append({ label: i18n("视频"), url: row.videosUrl, row: -1, icon: "folder-videos" })
                videosDone = true
            }
            placeEntries.append({ label: label, url: url, row: i, icon: placeIcon(label) })
        }
        if (!videosDone && row.showVideos) {
            placeEntries.append({ label: i18n("视频"), url: row.videosUrl, row: -1, icon: "folder-videos" })
        }
    }

    Component.onCompleted: rebuildPlaceEntries()

    Connections {
        target: row.placesModel
        ignoreUnknownSignals: true
        function onCountChanged() {
            row.rebuildPlaceEntries()
        }
    }

    implicitHeight: Math.round(Kirigami.Units.gridUnit * 2.2)

    ListView {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        orientation: ListView.Horizontal
        spacing: 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        model: placeEntries

        delegate: PlasmaComponents3.ItemDelegate {
            width: implicitWidth
            height: ListView.view.height
            leftPadding: 6
            rightPadding: 6

            contentItem: RowLayout {
                spacing: 4

                Kirigami.Icon {
                    source: model.icon
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                }

                PlasmaComponents3.Label {
                    text: model.label
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }

            onClicked: {
                if (model.row >= 0) {
                    if (row.placesModel && row.placesModel.trigger(model.row, "", null)) {
                        row.closeRequested()
                    }
                } else {
                    Qt.openUrlExternally(model.url)
                    row.closeRequested()
                }
            }

            PlasmaComponents3.ToolTip.text: model.url
            PlasmaComponents3.ToolTip.visible: hovered
            PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
