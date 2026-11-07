import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: area

    property var applet: null
    property var favoritesModel: null

    signal closeRequested()

    readonly property int unit: Math.max(36, Math.min(64, Plasmoid.configuration.tileUnit > 0 ? Plasmoid.configuration.tileUnit : 48))
    readonly property int columns: 6
    readonly property int gap: 6

    property var groups: []
    property int totalTiles: 0

    property var dragInfo: null
    property point dragPos: Qt.point(0, 0)
    property bool externalDrag: false
    property int selectedGroup: 0

    Component.onCompleted: {
        load()
        const saved = Plasmoid.configuration.selectedGroup
        selectGroup(Number.isFinite(saved) ? saved : 0)
    }

    function selectGroup(index) {
        if (groups.length === 0) {
            return
        }
        const gi = Math.max(0, Math.min(index, groups.length - 1))
        selectedGroup = gi
        Plasmoid.configuration.selectedGroup = gi
    }

    function load() {
        let data = null
        try {
            data = JSON.parse(Plasmoid.configuration.tileLayout || "{}")
        } catch (e) {
            data = null
        }
        if (data && Array.isArray(data.groups) && data.groups.length > 0) {
            groups = data.groups
        } else {
            groups = [{ name: i18n("常用"), tiles: [] }]
        }
        recount()
    }

    function save() {
        Plasmoid.configuration.tileLayout = JSON.stringify({ groups: groups })
    }

    function touch() {
        groups = JSON.parse(JSON.stringify(groups))
        recount()
        save()
    }

    function recount() {
        let n = 0
        for (const g of groups) {
            n += g.tiles.length
        }
        totalTiles = n
    }

    function hasTile(type, key) {
        for (const g of groups) {
            for (const t of g.tiles) {
                if (t.type === type && (t.favoriteId === key || t.url === key)) {
                    return true
                }
            }
        }
        return false
    }

    function pinApp(favoriteId, label, icon) {
        pinAppTo(area.selectedGroup, favoriteId, label, icon)
    }

    function pinAppTo(groupIndex, favoriteId, label, icon) {
        if (!favoriteId || hasTile("app", favoriteId)) {
            return
        }
        if (groups.length === 0) {
            groups = [{ name: i18n("常用"), tiles: [] }]
        }
        const gi = Math.max(0, Math.min(groupIndex, groups.length - 1))
        groups[gi].tiles.push({
            type: "app",
            favoriteId: favoriteId,
            label: label,
            icon: typeof icon === "string" ? icon : "",
            size: "medium"
        })
        area.selectGroup(gi)
        if (favoritesModel && !favoritesModel.isFavorite(favoriteId)) {
            favoritesModel.addFavorite(favoriteId, favoritesModel.count)
        }
        touch()
    }

    function pinPlace(url, label) {
        if (!url || hasTile("place", url)) {
            return
        }
        if (groups.length === 0) {
            groups = [{ name: i18n("常用"), tiles: [] }]
        }
        const gi = Math.max(0, Math.min(area.selectedGroup, groups.length - 1))
        groups[gi].tiles.push({
            type: "place",
            url: url,
            label: label,
            icon: String(url).startsWith("trash:") ? "user-trash" : "folder",
            size: "small"
        })
        area.selectGroup(gi)
        touch()
    }

    function launch(tile) {
        if (!tile) {
            return
        }
        if (tile.type === "app") {
            const fm = favoritesModel
            if (!fm) {
                return
            }
            let i = fm.favorites.indexOf(tile.favoriteId)
            if (i < 0) {
                fm.addFavorite(tile.favoriteId, fm.count)
                i = fm.favorites.indexOf(tile.favoriteId)
            }
            if (i >= 0 && fm.trigger(i, "", null)) {
                area.closeRequested()
            }
        } else if (tile.type === "place") {
            Qt.openUrlExternally(tile.url)
            area.closeRequested()
        }
    }

    function unpin(groupIndex, tileIndex) {
        const tile = groups[groupIndex].tiles[tileIndex]
        groups[groupIndex].tiles.splice(tileIndex, 1)
        if (tile.type === "app" && !hasTile("app", tile.favoriteId)) {
            if (favoritesModel && favoritesModel.isFavorite(tile.favoriteId)) {
                favoritesModel.removeFavorite(tile.favoriteId)
            }
        }
        touch()
    }

    function setSize(groupIndex, tileIndex, size) {
        groups[groupIndex].tiles[tileIndex].size = size
        touch()
    }

    function addGroup(name) {
        groups.push({ name: name, tiles: [] })
        touch()
    }

    function renameGroup(index, name) {
        groups[index].name = name
        touch()
    }

    function removeGroup(index) {
        if (groups.length <= 1) {
            return
        }
        groups.splice(index, 1)
        touch()
    }

    function startDrag(groupIndex, tileIndex, tileData) {
        dragInfo = { group: groupIndex, index: tileIndex, tile: tileData }
        const col = groupRepeater.itemAt(groupIndex)
        if (col) {
            const item = col.tilesRepeater.itemAt(tileIndex)
            if (item) {
                dragPos = item.mapToItem(area, item.width / 2, item.height / 2)
            }
        }
    }

    function startExternalDrag(favoriteId, label, icon, sceneX, sceneY) {
        if (!favoriteId) {
            return
        }
        externalDrag = true
        dragInfo = {
            group: -1,
            index: -1,
            tile: { type: "app", favoriteId: favoriteId, label: label, icon: icon, size: "medium" }
        }
        dragPos = area.mapFromItem(null, sceneX, sceneY)
    }

    function endExternalDrag(sceneX, sceneY) {
        if (!externalDrag) {
            return
        }
        externalDrag = false
        const p = area.mapFromItem(null, sceneX, sceneY)
        const info = dragInfo
        dragInfo = null
        if (!info || p.x < 0 || p.x > area.width || p.y < 0 || p.y > area.height) {
            return
        }

        // 落在哪个分组就加到哪个分组；落在空白处则加到当前选中的分组
        let target = area.selectedGroup
        for (let gi = 0; gi < area.groups.length; ++gi) {
            const col = groupRepeater.itemAt(gi)
            if (!col) {
                continue
            }
            const q = col.mapFromItem(null, sceneX, sceneY)
            if (q.x >= 0 && q.x <= col.width && q.y >= 0 && q.y <= col.height) {
                target = gi
                break
            }
        }
        area.pinAppTo(target, info.tile.favoriteId, info.tile.label, info.tile.icon)
    }

    function cancelExternalDrag() {
        if (externalDrag) {
            externalDrag = false
            dragInfo = null
        }
    }

    function updateDrag(sceneX, sceneY) {
        if (!dragInfo) {
            return
        }
        dragPos = area.mapFromItem(null, sceneX, sceneY)
    }

    function endDrag(sceneX, sceneY) {
        if (!dragInfo) {
            return
        }
        const info = dragInfo
        dragInfo = null

        for (let gi = 0; gi < area.groups.length; ++gi) {
            const col = groupRepeater.itemAt(gi)
            if (!col) {
                continue
            }
            const grid = col.grid
            const p = grid.mapFromItem(null, sceneX, sceneY)
            if (p.x < 0 || p.x > grid.width || p.y < 0 || p.y > grid.height) {
                continue
            }
            let target = col.tilesRepeater.count
            for (let ti = 0; ti < col.tilesRepeater.count; ++ti) {
                const item = col.tilesRepeater.itemAt(ti)
                if (p.x >= item.x && p.x <= item.x + item.width && p.y >= item.y && p.y <= item.y + item.height) {
                    target = p.x > item.x + item.width / 2 ? ti + 1 : ti
                    break
                }
            }
            area.moveTile(info.group, info.index, gi, target)
            return
        }
    }

    function moveTile(fromGroup, fromIndex, toGroup, toIndex) {
        if (fromGroup === toGroup && (toIndex === fromIndex || toIndex === fromIndex + 1)) {
            return
        }
        const tile = area.groups[fromGroup].tiles.splice(fromIndex, 1)[0]
        let idx = toIndex
        if (fromGroup === toGroup && fromIndex < toIndex) {
            idx -= 1
        }
        area.groups[toGroup].tiles.splice(idx, 0, tile)
        area.touch()
    }

    function spanFor(size, axis) {
        if (size === "small") {
            return 1
        }
        if (size === "wide") {
            return axis === "w" ? 4 : 2
        }
        if (size === "large") {
            return 4
        }
        return 2
    }

    function gridSize(size, axis) {
        const n = spanFor(size, axis)
        return n * area.unit + (n - 1) * area.gap
    }

    PlasmaExtras.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.gridUnit * 3
        visible: area.totalTiles === 0
        iconName: "preferences-desktop-icons"
        text: i18n("还没有磁贴")
        explanation: i18n("右键应用选“固定到开始屏幕”，或直接把应用拖到某个分组里")
    }

    Flickable {
        id: flick
        anchors.fill: parent
        visible: area.totalTiles > 0
        clip: true
        contentWidth: width
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            width: flick.width
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                id: groupRepeater
                model: area.groups

                delegate: ColumnLayout {
                    id: groupColumn

                    property var groupData: modelData
                    property int groupIndex: index

                    property alias grid: gridLayout
                    property alias tilesRepeater: tileRepeater

                    Layout.fillWidth: true
                    spacing: 2

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: headerRow.implicitHeight
                        radius: 3
                        color: "transparent"

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: area.selectGroup(groupColumn.groupIndex)
                        }

                        RowLayout {
                            id: headerRow
                            anchors.fill: parent
                            spacing: 4

                            PlasmaComponents3.Label {
                                text: groupColumn.groupData.name
                                font.bold: true
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                opacity: 0.75
                            }

                        Item {
                            Layout.fillWidth: true
                        }

                        PlasmaComponents3.ToolButton {
                            icon.name: "list-add"
                            text: i18n("新建分组")
                            display: PlasmaComponents3.AbstractButton.IconOnly
                            onClicked: area.openGroupDialog(-1, "add")
                            PlasmaComponents3.ToolTip.text: i18n("新建分组")
                            PlasmaComponents3.ToolTip.visible: hovered
                            PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }

                        PlasmaComponents3.ToolButton {
                            icon.name: "overflow-menu"
                            text: i18n("分组菜单")
                            display: PlasmaComponents3.AbstractButton.IconOnly
                            onClicked: {
                                area.menuGroupIndex = groupColumn.groupIndex
                                groupMenu.popup()
                            }
                            PlasmaComponents3.ToolTip.text: i18n("分组菜单")
                            PlasmaComponents3.ToolTip.visible: hovered
                            PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }
                        }
                    }

                    GridLayout {
                        id: gridLayout
                        Layout.alignment: Qt.AlignHCenter
                        columns: area.columns
                        columnSpacing: area.gap
                        rowSpacing: area.gap

                        Repeater {
                            id: tileRepeater
                            model: groupColumn.groupData.tiles

                            delegate: WinTile {
                                id: winTile

                                tileData: modelData
                                unit: area.unit

                                Layout.columnSpan: area.spanFor(tileData.size, "w")
                                Layout.rowSpan: area.spanFor(tileData.size, "h")
                                Layout.preferredWidth: area.gridSize(tileData.size, "w")
                                Layout.preferredHeight: area.gridSize(tileData.size, "h")

                                onActivated: area.launch(tileData)
                                onDragStarted: area.startDrag(groupColumn.groupIndex, index, tileData)
                                onDragMoved: (x, y) => area.updateDrag(x, y)
                                onDragEnded: (x, y) => area.endDrag(x, y)
                                onContextRequested: {
                                    area.menuGroupIndex = groupColumn.groupIndex
                                    area.menuTileIndex = index
                                    tileMenu.popup()
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.smallSpacing
            }
        }
    }

    Rectangle {
        id: dragGhost
        visible: area.dragInfo !== null
        z: 100
        x: Math.round(area.dragPos.x - width / 2)
        y: Math.round(area.dragPos.y - height / 2)
        width: area.dragInfo ? area.gridSize(area.dragInfo.tile.size, "w") : 0
        height: area.dragInfo ? area.gridSize(area.dragInfo.tile.size, "h") : 0
        radius: Kirigami.Units.smallSpacing
        color: Qt.alpha(Kirigami.Theme.highlightColor, 0.55)
        border.color: Kirigami.Theme.highlightColor
        border.width: 1

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.round(parent.width * 0.4)
            height: width
            source: area.dragInfo && area.dragInfo.tile ? (area.dragInfo.tile.icon || "application-x-executable") : ""
        }
    }

    property int menuGroupIndex: -1
    property int menuTileIndex: -1

    PlasmaComponents3.Menu {
        id: tileMenu

        PlasmaComponents3.MenuItem {
            text: i18n("打开")
            icon.name: "document-open"
            onTriggered: {
                const t = area.groups[area.menuGroupIndex].tiles[area.menuTileIndex]
                area.launch(t)
            }
        }

        PlasmaComponents3.MenuSeparator {}

        PlasmaComponents3.MenuItem {
            text: i18n("小")
            checkable: true
            checked: area.currentMenuSize() === "small"
            onTriggered: area.setSize(area.menuGroupIndex, area.menuTileIndex, "small")
        }
        PlasmaComponents3.MenuItem {
            text: i18n("中")
            checkable: true
            checked: area.currentMenuSize() === "medium"
            onTriggered: area.setSize(area.menuGroupIndex, area.menuTileIndex, "medium")
        }
        PlasmaComponents3.MenuItem {
            text: i18n("宽")
            checkable: true
            checked: area.currentMenuSize() === "wide"
            onTriggered: area.setSize(area.menuGroupIndex, area.menuTileIndex, "wide")
        }
        PlasmaComponents3.MenuItem {
            text: i18n("大")
            checkable: true
            checked: area.currentMenuSize() === "large"
            onTriggered: area.setSize(area.menuGroupIndex, area.menuTileIndex, "large")
        }

        PlasmaComponents3.MenuSeparator {}

        PlasmaComponents3.MenuItem {
            text: i18n("取消固定")
            icon.name: "edit-delete"
            onTriggered: area.unpin(area.menuGroupIndex, area.menuTileIndex)
        }
    }

    function currentMenuSize() {
        if (area.menuGroupIndex < 0 || area.menuTileIndex < 0) {
            return ""
        }
        return area.groups[area.menuGroupIndex].tiles[area.menuTileIndex].size
    }

    PlasmaComponents3.Menu {
        id: groupMenu

        PlasmaComponents3.MenuItem {
            text: i18n("重命名分组")
            icon.name: "edit-rename"
            onTriggered: area.openGroupDialog(area.menuGroupIndex, "rename")
        }

        PlasmaComponents3.MenuItem {
            text: i18n("删除分组")
            icon.name: "edit-delete"
            enabled: area.groups.length > 1
            onTriggered: area.removeGroup(area.menuGroupIndex)
        }
    }

    property int dialogGroupIndex: -1
    property string dialogMode: "add"

    function openGroupDialog(index, mode) {
        area.dialogGroupIndex = index
        area.dialogMode = mode
        groupNameField.text = index >= 0 ? area.groups[index].name : ""
        groupDialog.open()
    }

    QQC2.Dialog {
        id: groupDialog
        parent: area
        anchors.centerIn: parent
        modal: true
        title: area.dialogMode === "add" ? i18n("新建分组") : i18n("重命名分组")
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel

        onAccepted: {
            const name = groupNameField.text.trim()
            if (name.length === 0) {
                return
            }
            if (area.dialogMode === "add") {
                area.addGroup(name)
            } else {
                area.renameGroup(area.dialogGroupIndex, name)
            }
        }

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.TextField {
                id: groupNameField
                Layout.fillWidth: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 12
                placeholderText: i18n("分组名称")
            }
        }
    }
}
