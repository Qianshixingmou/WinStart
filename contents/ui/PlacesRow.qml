import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// 侧栏收起时，文件夹快捷入口显示在磁贴下方的这一行
Item {
    id: row

    property var placesModel: null

    signal closeRequested()

    implicitHeight: Math.round(Kirigami.Units.gridUnit * 2.2)

    ListView {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        orientation: ListView.Horizontal
        spacing: 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        model: row.placesModel

        delegate: PlasmaComponents3.ItemDelegate {
            id: placeItem

            readonly property bool hiddenItem: String(model.url ?? "").startsWith("recent") || String(model.url ?? "").length === 0

            width: hiddenItem ? 0 : implicitWidth
            height: hiddenItem ? 0 : ListView.view.height
            visible: !hiddenItem
            leftPadding: 6
            rightPadding: 6

            text: model.display

            contentItem: RowLayout {
                spacing: 4

                Kirigami.Icon {
                    source: model.decoration ?? ""
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                }

                PlasmaComponents3.Label {
                    text: placeItem.text
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }

            onClicked: {
                if (row.placesModel && row.placesModel.trigger(index, "", null)) {
                    row.closeRequested()
                }
            }

            PlasmaComponents3.ToolTip.text: String(model.url ?? "")
            PlasmaComponents3.ToolTip.visible: hovered && !hiddenItem
            PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
