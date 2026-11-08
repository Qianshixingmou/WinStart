import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

// 统一的“应用条目”接口：任何列表只要用 AppRow + appActions，
// 就自动获得 点击启动/唤起、右键固定、拖到磁贴 这一套行为。
Item {
    id: row

    property var appActions: null
    property var appModel: null
    property int appRowIndex: -1
    property string favoriteId: ""
    property string label: ""
    property string icon: ""

    implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.7)
    width: parent ? parent.width : 0

    function activate() {
        if (row.appActions) {
            row.appActions.activate(row.favoriteId, row.appModel, row.appRowIndex)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 3
        color: mouseArea.containsMouse ? Qt.alpha(Kirigami.Theme.highlightColor, 0.1) : "transparent"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 6

        Kirigami.Icon {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            source: row.icon
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: row.label
            elide: Text.ElideRight
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

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
            const p = mapToItem(null, mouse.x, mouse.y)
            if (!dragging && Math.hypot(mouse.x - pressPoint.x, mouse.y - pressPoint.y) > 8) {
                dragging = true
                if (row.appActions) {
                    row.appActions.dragStarted(row.favoriteId, row.label, row.icon, p.x, p.y)
                }
            }
            if (dragging && row.appActions) {
                row.appActions.dragMoved(p.x, p.y)
            }
        }

        onReleased: mouse => {
            const p = mapToItem(null, mouse.x, mouse.y)
            if (dragging) {
                dragging = false
                suppressClick = true
                if (row.appActions) {
                    row.appActions.dragEnded(p.x, p.y)
                }
            } else if (mouse.button === Qt.RightButton) {
                menu.open(mouse.x, mouse.y)
            } else if (!suppressClick) {
                row.activate()
            }
        }

        onCanceled: {
            if (dragging) {
                dragging = false
                if (row.appActions) {
                    row.appActions.dragCanceled()
                }
            }
        }
    }

    PlasmaExtras.Menu {
        id: menu
        visualParent: row
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
    }

    Instantiator {
        model: 2

        delegate: PlasmaExtras.MenuItem {
            required property int index

            text: index === 0 ? i18n("固定到开始屏幕") : i18n("打开")
            icon: index === 0 ? "bookmark-new" : "document-open"
            enabled: index === 0 ? row.favoriteId.length > 0 : true

            onClicked: {
                if (index === 0) {
                    if (row.appActions) {
                        row.appActions.pin(row.favoriteId, row.label, row.icon)
                    }
                } else {
                    row.activate()
                }
            }
        }

        onObjectAdded: (index, object) => menu.addMenuItem(object)
        onObjectRemoved: (index, object) => menu.removeMenuItem(object)
    }
}
