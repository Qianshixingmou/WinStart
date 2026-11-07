import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

ListView {
    id: view

    property var runnerModel: null

    signal activated()

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    currentIndex: -1

    model: (runnerModel && runnerModel.count > 0) ? runnerModel.modelForRow(0) : null

    function triggerFirst() {
        if (count > 0) {
            triggerIndex(0)
        }
    }

    function triggerIndex(i) {
        const m = runnerModel ? runnerModel.modelForRow(0) : null
        if (m && m.trigger(i, "", null)) {
            view.activated()
        }
    }

    delegate: PlasmaComponents3.ItemDelegate {
        id: item

        width: ListView.view.width
        implicitHeight: Math.round(Kirigami.Units.gridUnit * 2.4)

        text: model.display
        onClicked: view.triggerIndex(index)

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                implicitHeight: Kirigami.Units.iconSizes.smallMedium
                source: model.decoration
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: model.display
                    elide: Text.ElideRight
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: model.description ?? ""
                    visible: text.length > 0
                    elide: Text.ElideRight
                    opacity: 0.6
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }
        }
    }
}
