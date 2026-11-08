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
    property var appActivator: null

    signal closeRequested()
    signal columnLayoutChanged(int count)
    signal previewChanged(bool preview)

    readonly property int unit: Math.max(36, Math.min(64, Plasmoid.configuration.tileUnit > 0 ? Plasmoid.configuration.tileUnit : 48))
    readonly property int columns: 6
    readonly property int gap: 6
    readonly property int columnGap: Math.round(area.unit * 0.6)
    // 拖动时槽位步长 = 被拖组的磁贴区高度 + 间距（多行组按多行算）
    readonly property int slotStep: {
        const grid = Math.max(0, Math.round(area.groupDragHeight - area.groupTitleHeight))
        const oneRow = area.unit * 2 + area.gap
        return Math.max(oneRow, grid) + area.gap
    }
    readonly property int columnWidth: area.columns * area.unit + (area.columns - 1) * area.gap

    // 每个 group: { name, column, tiles }
    property var groups: []
    property int totalTiles: 0

    property bool previewColumn: false
    onPreviewColumnChanged: previewChanged(previewColumn)

    readonly property int realColumnCount: {
        let c = 1
        for (const g of area.groups) {
            c = Math.max(c, (g.column ?? 0) + 1)
        }
        return c
    }
    readonly property int columnCount: realColumnCount

    onColumnCountChanged: columnLayoutChanged(columnCount)

    // 用于拖动时取几何信息
    property var groupItems: ({})
    property var columnItems: ({})

    property var dragInfo: null
    property point dragPos: Qt.point(0, 0)
    property bool externalDrag: false
    property int selectedGroup: 0

    property int groupDragIndex: -1
    property real frozenRowX: 0
    property string groupDragName: ""
    property point groupDragPos: Qt.point(0, 0)
    property real groupDragHeight: 80
    property real groupTitleHeight: 0
    readonly property int slotHeight: {
        const grid = Math.max(0, Math.round(area.groupDragHeight - area.groupTitleHeight))
        return Math.max(area.unit * 2 + area.gap, grid)
    }
    property bool dropAtEnd: false
    property int dropGapRows: 0

    property int dropColumn: -1
    property int dropIndex: -1
    property int alignGroupIndex: -1
    property real alignTargetY: 0
    property int alignTries: 0
    property real dropX: 0
    property real dropY: 0

    Component.onCompleted: {
        load()
        const saved = Plasmoid.configuration.selectedGroup
        selectGroup(Number.isFinite(saved) ? saved : 0)
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
            groups = [{ name: i18n("常用"), column: 0, tiles: [] }]
        }
        for (const g of groups) {
            if (!Number.isFinite(g.column)) {
                g.column = 0
            }
        }
        normalizeColumns()
        recount()
    }

    function save() {
        Plasmoid.configuration.tileLayout = JSON.stringify({ groups: groups })
    }

    function compactColumns() {
        let maxCol = 0
        for (const g of groups) {
            maxCol = Math.max(maxCol, g.column ?? 0)
        }
        const cols = []
        for (let c = 0; c <= maxCol; ++c) {
            cols.push([])
        }
        for (const g of groups) {
            const c = Math.max(0, Math.min(g.column ?? 0, maxCol))
            cols[c].push(g)
        }
        const nonEmpty = cols.filter(list => list.length > 0)
        const flat = []
        for (let c = 0; c < nonEmpty.length; ++c) {
            for (const g of nonEmpty[c]) {
                g.column = c
                flat.push(g)
            }
        }
        groups = flat
    }

    function touch() {
        compactColumns()
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

    function normalizeColumns() {
        const cols = []
        for (let c = 0; c < area.columnCount; ++c) {
            cols.push([])
        }
        for (const g of groups) {
            const c = Math.max(0, Math.min(g.column ?? 0, cols.length - 1))
            cols[c].push(g)
        }
        const nonEmpty = cols.filter(list => list.length > 0)
        const flat = []
        for (let c = 0; c < nonEmpty.length; ++c) {
            for (const g of nonEmpty[c]) {
                g.column = c
                flat.push(g)
            }
        }
        groups = flat
    }

    function columnsData() {
        const cols = []
        for (let c = 0; c < area.columnCount; ++c) {
            cols.push([])
        }
        for (const g of groups) {
            const c = Math.max(0, Math.min(g.column ?? 0, cols.length - 1))
            cols[c].push(g)
        }
        return cols
    }

    function rawGroupsForColumn(c) {
        const out = []
        for (let i = 0; i < groups.length; ++i) {
            if ((groups[i].column ?? 0) === c) {
                out.push({ gi: i, g: groups[i] })
            }
        }
        return out
    }

    function groupsForColumn(c) {
        const out = []
        for (let i = 0; i < groups.length; ++i) {
            if ((groups[i].column ?? 0) === c) {
                out.push({ gi: i, g: groups[i] })
            }
        }
        return out
    }

    function selectGroup(index) {
        if (groups.length === 0) {
            return
        }
        const gi = Math.max(0, Math.min(index, groups.length - 1))
        selectedGroup = gi
        Plasmoid.configuration.selectedGroup = gi
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
            groups = [{ name: i18n("常用"), column: 0, tiles: [] }]
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
            groups = [{ name: i18n("常用"), column: 0, tiles: [] }]
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
            if (appActivator && appActivator(tile.favoriteId)) {
                area.closeRequested()
                return
            }
            const fm = favoritesModel
            if (!fm) {
                return
            }
            const role = Qt.UserRole + 3 // KAStatsFavoritesModel 的 favoriteId 角色
            function findRow() {
                for (let i = 0; i < fm.count; ++i) {
                    if (String(fm.index(i, 0).data(role)) === String(tile.favoriteId)) {
                        return i
                    }
                }
                return -1
            }
            let row = findRow()
            if (row < 0) {
                fm.addFavorite(tile.favoriteId, fm.count)
                row = findRow()
            }
            if (row >= 0 && fm.trigger(row, "", null)) {
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
        const cols = area.columnsData()
        let lastCol = cols.length - 1
        const sel = area.groups[area.selectedGroup]
        if (sel) {
            lastCol = sel.column ?? 0
        }
        groups.push({ name: name, column: Math.max(0, lastCol), tiles: [] })
        touch()
    }

    function renameGroup(index, name) {
        groups[index].name = name
        touch()
    }

    function removeGroup(index) {
        if (index < 0 || index >= groups.length) {
            return
        }
        groups.splice(index, 1)
        normalizeColumns()
        if (groups.length > 0) {
            area.selectGroup(Math.min(area.selectedGroup, groups.length - 1))
        }
        touch()
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

    function groupItem(gi) {
        return area.groupItems[gi] ?? null
    }

    function groupAt(sceneX, sceneY, allowNearest) {
        let best = -1
        let bestDist = 1e9
        for (let gi = 0; gi < area.groups.length; ++gi) {
            const item = groupItem(gi)
            if (!item) {
                continue
            }
            const p = item.mapFromItem(null, sceneX, sceneY)
            if (p.x >= 0 && p.x <= item.width && p.y >= 0 && p.y <= item.height) {
                return gi
            }
            if (!allowNearest) {
                continue
            }
            const dx = p.x < 0 ? -p.x : (p.x > item.width ? p.x - item.width : 0)
            const dy = p.y < 0 ? -p.y : (p.y > item.height ? p.y - item.height : 0)
            const d = Math.hypot(dx, dy)
            if (d < bestDist) {
                bestDist = d
                best = gi
            }
        }
        return best
    }

    function startDrag(groupIndex, tileIndex, tileData) {
        dragInfo = { group: groupIndex, index: tileIndex, tile: tileData }
        const item = groupItem(groupIndex)
        if (item && item.tilesRepeater.itemAt(tileIndex)) {
            const t = item.tilesRepeater.itemAt(tileIndex)
            dragPos = t.mapToItem(area, t.width / 2, t.height / 2)
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
        const hit = groupAt(sceneX, sceneY, false)
        const target = hit >= 0 ? hit : area.selectedGroup
        area.pinAppTo(target, info.tile.favoriteId, info.tile.label, info.tile.icon)
    }

    function cancelExternalDrag() {
        externalDrag = false
        dragInfo = null
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

        const gi = groupAt(sceneX, sceneY, true)
        if (gi < 0) {
            return
        }
        const item = groupItem(gi)
        let target = item ? item.tilesRepeater.count : 0
        if (item) {
            const grid = item.grid
            const p = grid.mapFromItem(null, sceneX, sceneY)
            if (p.x >= 0 && p.x <= grid.width && p.y >= 0 && p.y <= grid.height) {
                for (let ti = 0; ti < item.tilesRepeater.count; ++ti) {
                    const t = item.tilesRepeater.itemAt(ti)
                    if (p.x >= t.x && p.x <= t.x + t.width && p.y >= t.y && p.y <= t.y + t.height) {
                        target = p.x > t.x + t.width / 2 ? ti + 1 : ti
                        break
                    }
                }
            }
        }
        area.moveTile(info.group, info.index, gi, target)
    }

    function cancelDrag() {
        dragInfo = null
        externalDrag = false
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

    // 落位后测量实际位置，与悬浮槽位对齐；有偏差就补一次上边距
    function alignDroppedGroup() {
        if (area.alignGroupIndex < 0 || area.alignTries >= 3) {
            return
        }
        const item = area.groupItem(area.alignGroupIndex)
        const g = area.groups[area.alignGroupIndex]
        if (!item || !g) {
            return
        }
        const actualY = item.mapToItem(area, 0, 0).y
        const actualBottom = actualY + item.height
        const delta = Math.round(area.alignTargetY - actualBottom)
        if (Math.abs(delta) >= 1) {
            g.gapBefore = Math.max(0, Math.round((g.gapBefore ?? 0) + delta))
            area.alignTries += 1
            area.touch()
            alignTimer.restart()
        }
    }

    Timer {
        id: alignTimer
        interval: 60
        onTriggered: area.alignDroppedGroup()
    }

    // ---- 分组拖动 ----
    function startGroupDrag(groupIndex, sceneX, sceneY) {
        frozenRowX = columnsRow.x
        groupDragIndex = groupIndex
        groupDragName = area.groups[groupIndex] ? area.groups[groupIndex].name : ""
        const item = area.groupItem(groupIndex)
        groupDragHeight = item ? item.height : Math.round(area.unit * 2.2)
        groupTitleHeight = (item && item.grid) ? Math.max(0, item.height - item.grid.height - 2) : Math.round(area.unit * 0.6)
        groupDragPos = area.mapFromItem(null, sceneX, sceneY)
    }

    function computeDrop(sceneX, sceneY) {
        if (area.groupDragIndex < 0) {
            return
        }
        const p = area.mapFromItem(null, sceneX, sceneY)
        const contentX = p.x + flick.contentX
        const contentY = p.y + flick.contentY

        area.dropAtEnd = false
        const realCount = area.realColumnCount
        let targetCol = -1
        for (let c = 0; c < realCount; ++c) {
            const col = area.columnItems[c]
            if (!col) {
                continue
            }
            if (contentX >= col.x - area.columnGap / 2 && contentX <= col.x + col.width + area.columnGap / 2) {
                targetCol = c
                break
            }
        }
        if (targetCol < 0) {
            const last = area.columnItems[realCount - 1]
            if (last && contentX > last.x + last.width + area.columnGap / 2) {
                // 拖到最右列之外：实时预览一个新列
                area.previewColumn = true
                area.dropColumn = realCount
                area.dropIndex = 0
                area.dropX = last.x + last.width + area.columnGap
                const k = Math.max(0, Math.floor(Math.max(0, p.y - area.groupTitleHeight) / area.slotStep))
                area.dropGapRows = k
                area.dropY = Math.max(0, Math.min(area.groupTitleHeight + k * area.slotStep, flick.height - area.slotHeight))
                return
            }
            targetCol = 0
        }
        area.previewColumn = false

        const effCol = Math.min(targetCol, realCount - 1)
        const colItem = area.columnItems[effCol]
        if (colItem) {
            // 以“指针上方最近的组”为锚点计算槽位；没有则用列顶部
            const raw = area.rawGroupsForColumn(effCol).filter(e => e.gi !== area.groupDragIndex)
            let prevPos = -1
            let prevBottom = colItem.y
            for (let i = 0; i < raw.length; ++i) {
                const item = area.groupItem(raw[i].gi)
                if (!item) {
                    continue
                }
                const bottom = colItem.y + item.y + item.height
                if (bottom <= contentY) {
                    prevPos = i
                    prevBottom = bottom
                }
            }
            const origin = (prevPos >= 0 ? prevBottom + area.gap : colItem.y) + area.groupTitleHeight
            const k = Math.max(0, Math.floor((contentY - origin) / area.slotStep))
            area.dropGapRows = k
            area.dropColumn = effCol
            area.dropIndex = prevPos + 1
            const top = colItem.mapToItem(area, 0, 0)
            area.dropX = top.x
            area.dropY = Math.max(0, Math.min(origin + k * area.slotStep - flick.contentY, flick.height - area.slotHeight))
        } else {
            area.dropColumn = effCol
            area.dropIndex = 0
            area.dropGapRows = 0
        }
    }

    function updateGroupDrag(sceneX, sceneY) {
        if (groupDragIndex < 0) {
            return
        }
        groupDragPos = area.mapFromItem(null, sceneX, sceneY)
        area.computeDrop(sceneX, sceneY)
    }

    function cancelGroupDrag() {
        groupDragIndex = -1
        dropColumn = -1
        dropIndex = -1
        previewColumn = false
    }

    function endGroupDrag(sceneX, sceneY) {
        const gi = area.groupDragIndex
        const dropCol = area.dropColumn
        const dropIdx = area.dropIndex
        const wasPreview = area.previewColumn
        area.groupDragIndex = -1
        area.dropColumn = -1
        area.dropIndex = -1
        area.previewColumn = false
        if (gi < 0 || groups.length <= 1) {
            return
        }

        const p = area.mapFromItem(null, sceneX, sceneY)
        const contentX = p.x + flick.contentX
        const contentY = p.y + flick.contentY

        const oldGroups = area.groups.slice()
        const oldAbs = []
        const oldH = []
        for (let i = 0; i < oldGroups.length; ++i) {
            const it = area.groupItem(i)
            oldAbs.push(it ? it.mapToItem(area, 0, 0).y + flick.contentY : 0)
            oldH.push(it ? it.height : Math.round(area.unit * 2.2))
        }

        const cols = area.columnsData()
        const g = area.groups[gi]
        let fromCol = -1
        let fromPos = -1
        for (let c = 0; c < cols.length; ++c) {
            const k = cols[c].indexOf(g)
            if (k >= 0) {
                fromCol = c
                fromPos = k
                cols[c].splice(k, 1)
                break
            }
        }
        if (fromCol < 0) {
            return
        }

        let targetCol = -1
        let insert = 0
        if (wasPreview) {
            targetCol = cols.length
            cols.push([])
            insert = 0
        } else if (dropCol >= 0) {
            targetCol = Math.min(dropCol, cols.length)
            if (targetCol === cols.length) {
                cols.push([])
            }
            insert = area.dropAtEnd
                ? cols[targetCol].length
                : Math.max(0, Math.min(dropIdx, cols[targetCol].length))
        } else {
            return
        }

        // 落在列末尾的空白区域时，记录一个上边距，让组停留在松手的位置
        // 槽位相对“上一个组”的底偏移 k 行，落位时直接换算成上边距
        // 新列同样要按 k 行留空，否则会先画在顶部再被校准推下来
        const gapBefore = Math.max(0, area.dropGapRows * area.slotStep)
        g.gapBefore = gapBefore

        cols[targetCol].splice(insert, 0, g)

        const nonEmpty = cols.filter(list => list.length > 0)
        const flat = []
        for (let c = 0; c < nonEmpty.length; ++c) {
            for (const gg of nonEmpty[c]) {
                gg.column = c
                flat.push(gg)
            }
        }

        // 其它组保持各自的绝对位置：只调整它们的上边距来抵消上方组的位置变化
        const cursor = ({})
        for (const gg of flat) {
            const c = gg.column
            const isFirst = !(c in cursor)
            const prevBottom = isFirst ? 0 : cursor[c]
            const base = isFirst ? 0 : prevBottom + area.gap
            const oldIndex = oldGroups.indexOf(gg)
            let y
            if (gg === g) {
                y = base + Math.max(0, g.gapBefore)
            } else {
                const desired = oldIndex >= 0 ? oldAbs[oldIndex] : base
                y = Math.max(base, desired)
            }
            gg.gapBefore = Math.max(0, Math.round(y - base))
            const h = (gg === g) ? area.groupDragHeight : (oldIndex >= 0 ? oldH[oldIndex] : Math.round(area.unit * 2.2))
            cursor[c] = y + h
        }

        area.groups = flat
        area.alignGroupIndex = flat.indexOf(g)
        area.alignTargetY = area.dropY + area.slotHeight
        area.alignTries = 0
        area.touch()
        alignTimer.restart()
    }

    PlasmaExtras.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.gridUnit * 3
        visible: area.totalTiles === 0
        iconName: "preferences-desktop-icons"
        text: i18n("还没有磁贴")
        explanation: i18n("右键应用选“固定到开始屏幕”，或直接把应用拖到某个分组里")
    }

    PlasmaComponents3.Button {
        visible: area.groups.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Math.round(area.unit * 1.5)
        text: i18n("新建分组")
        icon.name: "list-add"
        onClicked: area.openGroupDialog(-1, "add")
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: columnsRow.x + columnsRow.implicitWidth + area.gap
        contentHeight: columnsRow.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Row {
            id: columnsRow
            spacing: area.columnGap
            // 拖动期间固定横向偏移，避免窗口变宽时整行重新居中导致列跟着动
            x: area.groupDragIndex >= 0
               ? area.frozenRowX
               : Math.max(0, (flick.width - implicitWidth) / 2)

            Repeater {
                id: columnRepeater
                model: area.columnCount

                delegate: ColumnLayout {
                    id: columnColumn

                    property int columnIndex: index
                    property alias groupRepeater: innerGroupRepeater

                    width: area.columnWidth
                    spacing: area.gap

                    Repeater {
                        id: innerGroupRepeater
                        model: area.groupsForColumn(columnColumn.columnIndex)

                        delegate: ColumnLayout {
                            id: groupColumn

                            property var entry: modelData
                            property int groupIndex: entry.gi
                            property var groupData: entry.g

                            property alias grid: gridLayout
                            property alias tilesRepeater: tileRepeater

                            Layout.fillWidth: true
                            Layout.topMargin: groupColumn.groupData.gapBefore ?? 0
                            spacing: 2

                            Rectangle {
                                Layout.fillWidth: true
                                // 固定标题高度：不再随 + 按钮移除而变矮；槽位计算会用实际标题高度
                                implicitHeight: Math.round(area.unit * 0.7)
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

                                    Item {
                                        width: 22
                                        height: 22

                                        Kirigami.Icon {
                                            anchors.fill: parent
                                            source: "overflow-menu"
                                            opacity: 0.8
                                        }

                                        MouseArea {
                                            id: handleMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            // 拖动分组时不让外层 Flickable 抢走鼠标
                                            preventStealing: true

                                            property point pressPoint
                                            property bool dragging: false

                                            onPressed: mouse => {
                                                pressPoint = Qt.point(mouse.x, mouse.y)
                                                dragging = false
                                            }
                                            onPositionChanged: mouse => {
                                                if (!pressed) {
                                                    return
                                                }
                                                const p = mapToItem(null, mouse.x, mouse.y)
                                                if (!dragging && Math.hypot(mouse.x - pressPoint.x, mouse.y - pressPoint.y) > 6) {
                                                    dragging = true
                                                    area.startGroupDrag(groupColumn.groupIndex, p.x, p.y)
                                                }
                                                if (dragging) {
                                                    area.updateGroupDrag(p.x, p.y)
                                                }
                                            }
                                            onReleased: mouse => {
                                                if (dragging) {
                                                    dragging = false
                                                    const p = mapToItem(null, mouse.x, mouse.y)
                                                    area.endGroupDrag(p.x, p.y)
                                                } else {
                                                    area.menuGroupIndex = groupColumn.groupIndex
                                                    groupMenu.popup()
                                                }
                                            }
                                            onCanceled: {
                                                if (dragging) {
                                                    dragging = false
                                                    area.cancelGroupDrag()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            GridLayout {
                                id: gridLayout
                                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
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
                                        onDragCanceled: area.cancelDrag()
                                        onContextRequested: {
                                            area.menuGroupIndex = groupColumn.groupIndex
                                            area.menuTileIndex = index
                                            tileMenu.popup()
                                        }
                                    }
                                }
                            }
                        }

                        onItemAdded: (index, item) => {
                            area.groupItems[item.groupIndex] = item
                        }
                        onItemRemoved: (index, item) => {
                            if (area.groupItems[item.groupIndex] === item) {
                                delete area.groupItems[item.groupIndex]
                            }
                        }
                    }
                }

                onItemAdded: (index, item) => {
                    area.columnItems[index] = item
                }
                onItemRemoved: (index, item) => {
                    if (area.columnItems[index] === item) {
                        delete area.columnItems[index]
                    }
                }
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

    Rectangle {
        id: previewColumnBg
        visible: area.previewColumn && area.groupDragIndex >= 0
        z: 98
        x: Math.round(area.dropX)
        y: 0
        width: area.columnWidth
        height: flick.height
        radius: 4
        color: Qt.alpha(Kirigami.Theme.highlightColor, 0.06)
        border.color: Qt.alpha(Kirigami.Theme.highlightColor, 0.25)
        border.width: 1
    }

    Rectangle {
        id: dropSlot
        visible: area.groupDragIndex >= 0 && area.dropColumn >= 0
        z: 99
        x: Math.round(area.dropX)
        y: Math.round(area.dropY)
        width: area.columnWidth
        height: area.slotHeight
        radius: 4
        color: Qt.alpha(Kirigami.Theme.highlightColor, 0.12)
        border.color: Qt.alpha(Kirigami.Theme.highlightColor, 0.55)
        border.width: 1
    }

    Rectangle {
        id: groupGhost
        visible: area.groupDragIndex >= 0
        z: 101
        x: Math.round(area.groupDragPos.x - width / 2)
        y: Math.round(area.groupDragPos.y - height / 2)
        width: Math.min(160, groupLabel.implicitWidth + 20)
        height: 32
        radius: 4
        color: Qt.alpha(Kirigami.Theme.highlightColor, 0.55)
        border.color: Kirigami.Theme.highlightColor
        border.width: 1

        PlasmaComponents3.Label {
            id: groupLabel
            anchors.centerIn: parent
            text: area.groupDragName
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Kirigami.Theme.highlightedTextColor
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
        const g = area.groups[area.menuGroupIndex]
        if (!g || !g.tiles || area.menuTileIndex >= g.tiles.length) {
            return ""
        }
        return g.tiles[area.menuTileIndex].size
    }

    PlasmaComponents3.Menu {
        id: groupMenu

        PlasmaComponents3.MenuItem {
            text: i18n("新建分组")
            icon.name: "list-add"
            onTriggered: area.openGroupDialog(-1, "add")
        }

        PlasmaComponents3.MenuSeparator {}

        PlasmaComponents3.MenuItem {
            text: i18n("重命名分组")
            icon.name: "edit-rename"
            onTriggered: area.openGroupDialog(area.menuGroupIndex, "rename")
        }

        PlasmaComponents3.MenuItem {
            text: i18n("删除分组")
            icon.name: "edit-delete"
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
