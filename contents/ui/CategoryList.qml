import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// 系统分类模式：分类默认展开，分类头为图标 + 名称，应用行使用统一的 AppRow
Item {
    id: view

    property var model: null
    property var appActions: null

    signal closeRequested()

    readonly property var allAppsModel: view.model && view.model.count > 0 ? view.model.modelForRow(0) : null

    function isValidFavorite(fid) {
        const s = String(fid ?? "")
        return s.length > 0 && s !== "其他.desktop" && !s.endsWith("/其他.desktop")
    }

    // 没有被任何分类收录的应用（“其他”）；没有分类时就是全部应用
    readonly property var otherApps: {
        if (!view.allAppsModel) {
            return []
        }
        const covered = ({})
        if (view.anyCategory) {
            for (let i = 0; i < view.model.count; ++i) {
                const label = String(view.model.index(i, 0).data(Qt.DisplayRole) ?? "")
                if (label === i18n("全部应用") || label === i18n("全部应用程序")) {
                    continue
                }
                const ch = view.model.modelForRow(i)
                if (!ch) {
                    continue
                }
                for (let j = 0; j < ch.count; ++j) {
                    covered[String(ch.index(j, 0).data(Qt.UserRole + 3) ?? "")] = true
                }
            }
        }
        const out = []
        for (let j = 0; j < view.allAppsModel.count; ++j) {
            const idx = view.allAppsModel.index(j, 0)
            const fid = String(idx.data(Qt.UserRole + 3) ?? "")
            if (covered[fid] || !view.isValidFavorite(fid)) {
                continue
            }
            out.push({
                row: j,
                display: String(idx.data(Qt.DisplayRole) ?? ""),
                favoriteId: fid,
                icon: (typeof idx.data(Qt.DecorationRole) === "string") ? idx.data(Qt.DecorationRole) : ""
            })
        }
        return out
    }

    readonly property bool anyCategory: {
        if (!view.model) {
            return false
        }
        for (let i = 0; i < view.model.count; ++i) {
            const label = String(view.model.index(i, 0).data(Qt.DisplayRole) ?? "")
            if (label === i18n("全部应用") || label === i18n("全部应用程序")) {
                continue
            }
            const ch = view.model.modelForRow(i)
            if (ch && ch.count > 0) {
                return true
            }
        }
        return false
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn
            width: view.width
            spacing: 4

            Repeater {
                model: view.model

                delegate: ColumnLayout {
                    id: section

                    property string catLabel: String(model.display ?? "")
                    property var childModel: view.model ? view.model.modelForRow(index) : null
                    property bool isAllApps: catLabel === i18n("全部应用") || catLabel === i18n("全部应用程序")
                    property bool usable: catLabel.length > 0 && !isAllApps && childModel !== null && childModel.count > 0

                    Layout.fillWidth: true
                    visible: usable
                    spacing: 2
                    Layout.bottomMargin: 4

                    // 分类头：图标 + 分类名
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        spacing: 6

                        Kirigami.Icon {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            source: String(model.decoration ?? "").length > 0 ? model.decoration : "applications-other"
                            opacity: 0.85
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: section.catLabel
                            font.bold: true
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.75
                            elide: Text.ElideRight
                        }
                    }

                    Repeater {
                        model: section.childModel

                        delegate: AppRow {
                            Layout.fillWidth: true
                            Layout.leftMargin: 18
                            visible: view.isValidFavorite(String(model.favoriteId ?? ""))
                            Layout.preferredHeight: visible ? implicitHeight : 0

                            appActions: view.appActions
                            appModel: section.childModel
                            appRowIndex: index
                            favoriteId: String(model.favoriteId ?? "")
                            label: String(model.display ?? "")
                            icon: (typeof model.decoration === "string") ? model.decoration : ""
                        }
                    }
                }
            }

            // “其他”：没有归入任何分类的应用；没有分类时就是全部应用
            ColumnLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                spacing: 2
                visible: view.otherApps.length > 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    spacing: 6

                    Kirigami.Icon {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        source: "applications-other"
                        opacity: 0.85
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: i18n("其他")
                        font.bold: true
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.75
                    }
                }

                Repeater {
                    model: view.otherApps

                    delegate: AppRow {
                        Layout.fillWidth: true
                        Layout.leftMargin: 18

                        appActions: view.appActions
                        appModel: view.allAppsModel
                        appRowIndex: modelData.row
                        favoriteId: modelData.favoriteId
                        label: modelData.display
                        icon: modelData.icon
                    }
                }
            }
        }
    }
}
