import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

ListView {
    id: view

    signal activated(int index)
    signal pinRequested(string favoriteId, string label, string icon)
    signal drillRequested(int index, string label)
    signal recentActivated()

    signal appDragStarted(string favoriteId, string label, string icon, real sceneX, real sceneY)
    signal appDragMoved(real sceneX, real sceneY)
    signal appDragEnded(real sceneX, real sceneY)
    signal appDragCanceled()

    property bool enableSections: true
    property bool showChevron: false
    property var recentModel: null
    property bool showRecent: false

    property int menuIndex: -1
    property string menuFavoriteId: ""
    property string menuLabel: ""
    property string menuIcon: ""
    property Item menuVisualParent: null

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    currentIndex: -1
    cacheBuffer: 400

    function openMenu(parentItem, x, y) {
        menuVisualParent = parentItem
        contextMenu.open(x, y)
    }

    // 最近使用放在同一个 ListView 的 header 里，跟随列表一起滚动
    header: Item {
        id: headerItem

        width: view.width
        height: view.showRecent ? Math.round(Kirigami.Units.gridUnit * 2) + 4 * Math.round(Kirigami.Units.gridUnit * 1.7) : 0
        visible: height > 0

        Column {
            width: parent.width
            spacing: 0

            Item {
                width: parent.width
                height: Math.round(Kirigami.Units.gridUnit * 2)

                PlasmaComponents3.Label {
                    anchors.left: parent.left
                    anchors.leftMargin: Kirigami.Units.gridUnit * 0.8
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("最近使用")
                    opacity: 0.6
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }

            ListView {
                id: recentList
                width: parent.width
                height: Math.min(view.recentModel ? view.recentModel.count : 0, 4) * rowHeight
                interactive: false
                clip: true

                readonly property int rowHeight: Math.round(Kirigami.Units.gridUnit * 1.7)

                model: view.recentModel

                delegate: Item {
                    id: recentItem

                    width: ListView.view.width
                    height: ListView.view.rowHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 3
                        color: recentMouse.containsMouse ? Qt.alpha(Kirigami.Theme.highlightColor, 0.22) : "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 28
                        spacing: 6

                        Kirigami.Icon {
                            source: model.decoration ?? ""
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: model.display
                            elide: Text.ElideRight
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }

                    MouseArea {
                        id: recentMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                view.menuIndex = -1
                                view.menuFavoriteId = String(model.favoriteId ?? "")
                                view.menuLabel = String(model.display ?? "")
                                view.menuIcon = (typeof model.decoration === "string") ? model.decoration : ""
                                view.openMenu(recentItem, mouse.x, mouse.y)
                            } else if (view.recentModel && view.recentModel.trigger(index, "", null)) {
                                view.recentActivated()
                            }
                        }
                    }

                }
            }
        }
    }

    // 按 Kicker 的 group 角色分组（中文应用按拼音首字母分组）
    section.property: enableSections ? "group" : ""
    section.criteria: ViewSection.FullString
    section.delegate: Item {
        id: sectionHeader
        width: ListView.view ? ListView.view.width : 0
        height: Math.round(Kirigami.Units.gridUnit * 1.7)

        PlasmaComponents3.Label {
            anchors.left: parent.left
            anchors.leftMargin: Kirigami.Units.gridUnit * 0.8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Kirigami.Units.smallSpacing * 0.5
            text: section === "&" ? "#" : section
            font.bold: true
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.65
        }
    }

    // 自己实现条目：左键启动、右键菜单、拖动到磁贴区
    delegate: Item {
        id: item

        readonly property bool isCategory: view.showChevron && (model.hasChildren ?? false)

        width: ListView.view.width
        height: Math.round(Kirigami.Units.gridUnit * 1.8)

        Accessible.name: model.display
        Accessible.role: Accessible.ListItem
        Accessible.onPressAction: {
            if (item.isCategory) {
                view.drillRequested(index, String(model.display ?? ""))
            } else {
                view.activated(index)
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 3
            color: itemMouse.containsMouse ? Qt.alpha(Kirigami.Theme.highlightColor, 0.22) : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 30
            spacing: 6

            Kirigami.Icon {
                source: model.decoration ?? ""
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: model.display
                elide: Text.ElideRight
            }

            Kirigami.Icon {
                visible: item.isCategory
                source: "arrow-right"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                opacity: 0.6
            }
        }

        MouseArea {
            id: itemMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            // 拖拽应用时不要让 ListView 抢走鼠标（否则往上下拖会变滚动，拖拽被取消）
            preventStealing: true

            property point pressPoint
            property bool dragging: false
            property bool suppressClick: false

            onPressed: mouse => {
                pressPoint = Qt.point(mouse.x, mouse.y)
                dragging = false
                suppressClick = false
            }

            onPositionChanged: mouse => {
                if (!pressed) {
                    return
                }
                if (!dragging && Math.hypot(mouse.x - pressPoint.x, mouse.y - pressPoint.y) > 10) {
                    dragging = true
                    view.interactive = false
                    const p = item.mapToItem(null, mouse.x, mouse.y)
                    view.appDragStarted(String(model.favoriteId ?? ""), String(model.display ?? ""), (typeof model.decoration === "string") ? model.decoration : "", p.x, p.y)
                }
                if (dragging) {
                    const p = item.mapToItem(null, mouse.x, mouse.y)
                    view.appDragMoved(p.x, p.y)
                }
            }

            onReleased: mouse => {
                view.interactive = true
                if (dragging) {
                    const p = item.mapToItem(null, mouse.x, mouse.y)
                    dragging = false
                    suppressClick = true
                    view.appDragEnded(p.x, p.y)
                }
            }

            onCanceled: {
                view.interactive = true
                dragging = false
                view.appDragCanceled()
            }

            onClicked: mouse => {
                if (suppressClick) {
                    suppressClick = false
                    return
                }
                if (mouse.button === Qt.RightButton) {
                    view.menuIndex = index
                    view.menuFavoriteId = String(model.favoriteId ?? "")
                    view.menuLabel = String(model.display ?? "")
                    view.menuIcon = (typeof model.decoration === "string") ? model.decoration : ""
                    view.openMenu(item, mouse.x, mouse.y)
                } else if (item.isCategory) {
                    view.drillRequested(index, String(model.display ?? ""))
                } else {
                    view.activated(index)
                }
            }
        }
    }

    PlasmaExtras.Menu {
        id: contextMenu
        visualParent: view.menuVisualParent
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
    }

    Instantiator {
        model: 2

        delegate: PlasmaExtras.MenuItem {
            required property int index

            text: index === 0 ? i18n("固定到开始屏幕") : i18n("打开")
            icon: index === 0 ? "bookmark-new" : "document-open"
            enabled: index === 0 ? view.menuFavoriteId.length > 0 : view.menuIndex >= 0

            onClicked: {
                if (index === 0) {
                    view.pinRequested(view.menuFavoriteId, view.menuLabel, view.menuIcon)
                } else if (view.menuIndex >= 0) {
                    view.activated(view.menuIndex)
                }
            }
        }

        onObjectAdded: (index, object) => contextMenu.addMenuItem(object)
        onObjectRemoved: (index, object) => contextMenu.removeMenuItem(object)
    }
}
