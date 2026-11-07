import QtQuick

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Rectangle {
    id: tile

    property var tileData: null
    property int unit: 48
    property bool hovered: false
    property bool dragging: false

    signal activated()
    signal contextRequested()
    signal dragStarted()
    signal dragMoved(real sceneX, real sceneY)
    signal dragEnded(real sceneX, real sceneY)
    signal dragCanceled()

    readonly property string size: tileData && tileData.size ? tileData.size : "medium"
    readonly property int gridW: size === "small" ? 1 : (size === "wide" || size === "large") ? 4 : 2
    readonly property int gridH: size === "small" ? 1 : (size === "wide") ? 2 : (size === "large") ? 4 : 2

    radius: Kirigami.Units.smallSpacing
    color: hovered ? Qt.alpha(Kirigami.Theme.highlightColor, 0.38)
                   : Qt.alpha(Kirigami.Theme.highlightColor, 0.22)
    opacity: dragging ? 0.35 : 1

    Behavior on color {
        ColorAnimation { duration: Kirigami.Units.shortDuration }
    }

    Kirigami.Icon {
        id: icon

        anchors.centerIn: parent
        anchors.verticalCenterOffset: label.visible ? -Math.round(label.height / 2) : 0
        width: size === "small" ? Math.round(tile.unit * 0.55)
             : size === "large" ? Math.round(tile.unit * 1.6)
             : Math.round(tile.unit * 1.1)
        height: width
        source: tile.tileData && tile.tileData.icon ? tile.tileData.icon : "application-x-executable"
    }

    PlasmaComponents3.Label {
        id: label
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        visible: tile.size !== "small"
        text: tile.tileData ? (tile.tileData.label ?? "") : ""
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignLeft
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        color: Kirigami.Theme.textColor
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        // 拖动磁贴时不要让外层 Flickable 抢走鼠标
        preventStealing: true

        property point pressPoint
        property bool suppressClick: false

        onEntered: tile.hovered = true
        onExited: tile.hovered = false

        onPressed: mouse => {
            pressPoint = Qt.point(mouse.x, mouse.y)
            suppressClick = false
        }

        onPositionChanged: mouse => {
            if (!pressed) {
                return
            }
            if (!tile.dragging && Math.hypot(mouse.x - pressPoint.x, mouse.y - pressPoint.y) > 8) {
                tile.dragging = true
                tile.dragStarted()
            }
            if (tile.dragging) {
                const p = tile.mapToItem(null, mouse.x, mouse.y)
                tile.dragMoved(p.x, p.y)
            }
        }

        onReleased: mouse => {
            if (tile.dragging) {
                const p = tile.mapToItem(null, mouse.x, mouse.y)
                tile.dragging = false
                suppressClick = true
                tile.dragEnded(p.x, p.y)
            }
        }

        onCanceled: {
            if (tile.dragging) {
                tile.dragging = false
                tile.dragCanceled()
            }
        }

        onClicked: mouse => {
            if (suppressClick) {
                suppressClick = false
                return
            }
            if (mouse.button === Qt.RightButton) {
                tile.contextRequested()
            } else {
                tile.activated()
            }
        }
    }
}
