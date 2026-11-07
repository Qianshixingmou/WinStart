import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls as QQC2

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var applet: null
    property int modelRevision: 0

    readonly property bool categoryMode: Plasmoid.configuration.listMode === 1
    property var drilledModel: null
    property string drilledName: ""

    readonly property int u: Kirigami.Units.gridUnit

    // 宽度固定：磁贴列、分界线不动；侧栏展开时应用列表变窄，收起时应用列表吃掉侧栏的宽度
    readonly property int railWidth: Math.round(u * 3.9)
    property int tileColumns: 1
    property int lastTileColumns: 1
    property bool previewingColumn: false
    onPreviewingColumnChanged: Qt.callLater(syncPopupSize)
    readonly property var popupWindow: Window.window
    readonly property int columnStep: Math.round(u * 19.3)
    readonly property int baseTilesWidth: Math.round(u * 19.33)
    readonly property int tilesWidth: baseTilesWidth + Math.max(0, tileColumns - 1 + (previewingColumn ? 1 : 0)) * columnStep
    readonly property int appWidthExpanded: Math.round(u * 15)
    readonly property int appWidthCollapsed: appWidthExpanded + railWidth + 1
    readonly property int contentWidth: appWidthExpanded + railWidth + 1 + 1 + tilesWidth

    readonly property int popupHeight: Math.min(Plasmoid.configuration.popupHeight,
                                                Math.round(Screen.desktopAvailableHeight - u * 2))

    implicitWidth: contentWidth
    implicitHeight: popupHeight
    Layout.minimumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.maximumWidth: implicitWidth
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    Component.onCompleted: {
        Qt.callLater(function() {
            if (tileArea) {
                tileColumns = tileArea.columnCount
                lastTileColumns = tileColumns
            }
        })
        rootModel.appletInterface = root.applet
        runnerSource.appletInterface = root.applet
        placesSource.appletInterface = root.applet
        rootModel.refresh()
    }

    function syncPopupSize() {
        const w = root.popupWindow
        if (!w || !root.applet || !root.applet.expanded) {
            return
        }
        w.width = root.contentWidth
    }

    function drillInto(index, label) {
        const m = rootModel.modelForRow(index)
        if (m) {
            root.drilledModel = m
            root.drilledName = label
        }
    }

    Connections {
        target: tileArea
        function onPreviewChanged(preview) {
            root.previewingColumn = preview
        }
    }

    Connections {
        target: tileArea
        function onColumnLayoutChanged(count) {
            root.tileColumns = count
            root.lastTileColumns = count
            Qt.callLater(root.syncPopupSize)
        }
    }

    Connections {
        target: root.applet
        function onExpandedChanged() {
            if (root.applet && !root.applet.expanded && tileArea) {
                tileArea.cancelDrag()
            }
        }
    }

    function closeMenu() {
        if (root.applet) {
            root.applet.expanded = false
        }
    }

    // 所有应用的扁平模型（RootModel 的第 0 行是"全部应用"分组）
    readonly property var allAppsModel: {
        root.modelRevision
        return rootModel.count > 0 ? rootModel.modelForRow(0) : null
    }

    Kicker.RootModel {
        id: rootModel

        autoPopulate: false
        appletInterface: root.applet
        appNameFormat: 0
        flat: !root.categoryMode
        sorted: true
        showSeparators: false
        showTopLevelItems: true
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        showFavoritesPlaceholder: false

        onRefreshed: root.modelRevision++

        Component.onCompleted: {
            if (favoritesModel) {
                favoritesModel.initForClient("org.qianshi.win10start.favorites." + Plasmoid.id)
            }
        }
    }

    Kicker.RunnerModel {
        id: runnerSource
        appletInterface: root.applet
        favoritesModel: rootModel.favoritesModel
        mergeResults: true
        runners: [
            "krunner_services",
            "krunner_systemsettings",
            "krunner_sessions",
            "krunner_powerdevil",
            "calculator",
            "unitconverter"
        ]
    }

    Kicker.RecentUsageModel {
        id: recentSource
        favoritesModel: rootModel.favoritesModel
        ordering: 0
    }

    Kicker.ComputerModel {
        id: placesSource
        appletInterface: root.applet
        favoritesModel: rootModel.favoritesModel
        systemApplications: []
    }

    Kicker.SystemModel {
        id: powerSource
    }

    ColumnLayout {
        id: rootLayout
        anchors.fill: parent
        spacing: 0

        Row {
            id: mainRow
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

        Rail {
            id: railItem
            visible: Plasmoid.configuration.railVisible
            width: visible ? root.railWidth : 0
            height: parent.height

            applet: root.applet
            placesModel: placesSource
            systemModel: powerSource

            onCloseRequested: root.closeMenu()
            onPinPlaceRequested: (url, label) => tileArea.pinPlace(url, label)
        }

        Rectangle {
            visible: railItem.visible
            width: visible ? 1 : 0
            height: parent.height
            color: Kirigami.Theme.textColor
            opacity: 0.12
        }

        // 中间：搜索 + 应用列表
        ColumnLayout {
            id: appColumn
            width: Plasmoid.configuration.railVisible ? root.appWidthExpanded : root.appWidthCollapsed
            height: parent.height
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Math.round(root.u * 0.5)
                spacing: Math.round(root.u * 0.4)

                PlasmaComponents3.ToolButton {
                    icon.name: "application-menu"
                    text: i18n("收起侧栏")
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    onClicked: Plasmoid.configuration.railVisible = !Plasmoid.configuration.railVisible
                    PlasmaComponents3.ToolTip.text: i18n("切换侧栏 / 底部栏")
                    PlasmaComponents3.ToolTip.visible: hovered
                }

                PlasmaComponents3.TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: i18n("搜索应用、文件和设置…")

                    onTextChanged: runnerSource.query = text

                    Keys.onEscapePressed: {
                        if (text.length > 0) {
                            text = ""
                        } else {
                            root.closeMenu()
                        }
                    }
                    Keys.onReturnPressed: searchResults.triggerFirst()
                    Keys.onEnterPressed: searchResults.triggerFirst()
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    visible: searchField.text.length === 0

                    // 所有应用（A–Z 分组）
                    AppListView {
                        id: appList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: !root.categoryMode && searchField.text.length === 0
                        model: root.allAppsModel
                        recentModel: recentSource
                        showRecent: Plasmoid.configuration.showRecent
                        onRecentActivated: root.closeMenu()
                        onActivated: index => {
                            if (root.allAppsModel && root.allAppsModel.trigger(index, "", null)) {
                                root.closeMenu()
                            }
                        }
                        onPinRequested: (favoriteId, label, icon) => tileArea.pinApp(favoriteId, label, icon)
                        onAppDragStarted: (favoriteId, label, icon, x, y) => tileArea.startExternalDrag(favoriteId, label, icon, x, y)
                        onAppDragMoved: (x, y) => tileArea.updateDrag(x, y)
                        onAppDragEnded: (x, y) => tileArea.endExternalDrag(x, y)
                        onAppDragCanceled: tileArea.cancelExternalDrag()
                    }

                    // 分类列表
                    AppListView {
                        id: categoryList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.categoryMode && root.drilledModel === null && searchField.text.length === 0
                        model: rootModel
                        recentModel: recentSource
                        showRecent: Plasmoid.configuration.showRecent
                        onRecentActivated: root.closeMenu()
                        onAppDragStarted: (favoriteId, label, icon, x, y) => tileArea.startExternalDrag(favoriteId, label, icon, x, y)
                        onAppDragMoved: (x, y) => tileArea.updateDrag(x, y)
                        onAppDragEnded: (x, y) => tileArea.endExternalDrag(x, y)
                        onAppDragCanceled: tileArea.cancelExternalDrag()
                        enableSections: false
                        showChevron: true
                        onDrillRequested: (index, label) => root.drillInto(index, label)
                        onActivated: index => {
                            if (rootModel.trigger(index, "", null)) {
                                root.closeMenu()
                            }
                        }
                    }

                    // 进入某个分类
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0
                        visible: root.categoryMode && root.drilledModel !== null && searchField.text.length === 0

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.margins: 4

                            PlasmaComponents3.ToolButton {
                                icon.name: "arrow-left"
                                text: i18n("返回")
                                display: PlasmaComponents3.AbstractButton.IconOnly
                                onClicked: root.drilledModel = null
                            }

                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: root.drilledName
                                font.bold: true
                                elide: Text.ElideRight
                            }
                        }

                        AppListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: root.drilledModel
                            enableSections: true
                            onActivated: index => {
                                if (root.drilledModel && root.drilledModel.trigger(index, "", null)) {
                                    root.closeMenu()
                                }
                            }
                        }
                    }
                }

                SearchResultsView {
                    id: searchResults
                    anchors.fill: parent
                    visible: searchField.text.length > 0
                    runnerModel: runnerSource
                    onActivated: root.closeMenu()
                }
            }

        }

        Rectangle {
            width: 1
            height: parent.height
            color: Kirigami.Theme.textColor
            opacity: 0.12
        }

        // 右侧：磁贴区
        Item {
            width: root.tilesWidth
            height: parent.height

            TileArea {
                id: tileArea
                anchors.fill: parent
                anchors.margins: Math.round(root.u * 0.5)
                applet: root.applet
                favoritesModel: rootModel.favoritesModel
                onCloseRequested: root.closeMenu()
            }
        }
        }

        BottomBar {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(root.u * 2.4)
            visible: !Plasmoid.configuration.railVisible
            placesModel: placesSource
            systemModel: powerSource
            onCloseRequested: root.closeMenu()
        }
    }
}
