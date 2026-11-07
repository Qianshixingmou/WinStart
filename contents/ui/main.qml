import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.icon: Plasmoid.configuration.icon

    readonly property bool onDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar

    switchWidth: fullRepresentationItem ? fullRepresentationItem.Layout.minimumWidth : Kirigami.Units.gridUnit * 24
    switchHeight: fullRepresentationItem ? fullRepresentationItem.Layout.minimumHeight : Kirigami.Units.gridUnit * 24

    fullRepresentation: FullRepresentation {
        applet: root
        focus: true
    }

    // 桌面/查看器里把完整界面当作“紧凑表示”铺开，方便预览；面板里仍是图标
    compactRepresentation: onDesktop ? desktopComponent : compactComponent

    Component {
        id: desktopComponent

        FullRepresentation {
            applet: root
            focus: true
        }
    }

    Component {
        id: compactComponent

        MouseArea {
            id: button

            readonly property int iconSize: Kirigami.Units.iconSizes.medium

            implicitWidth: iconSize
            implicitHeight: iconSize
            Layout.minimumWidth: implicitWidth
            Layout.minimumHeight: implicitHeight
            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: implicitHeight

            hoverEnabled: true
            Accessible.name: Plasmoid.title
            Accessible.role: Accessible.Button

            property bool wasExpanded: false

            onPressed: wasExpanded = root.expanded
            onClicked: root.expanded = !wasExpanded

            Kirigami.Icon {
                anchors.fill: parent
                source: Qt.resolvedUrl("../icons/start-menu.svg")
                active: button.containsMouse
                smooth: true
            }
        }
    }

    Component.onCompleted: {
        if (Plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            Plasmoid.activationTogglesExpanded = true
        }
    }
}
