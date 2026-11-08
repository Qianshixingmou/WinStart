import QtQuick
import org.kde.kirigami as Kirigami

// 侧栏 / 底栏共用的一套间距变量
QtObject {
    readonly property int edgeMargin: Math.round(Kirigami.Units.gridUnit * 0.9)
    readonly property int avatarSize: Math.round(Kirigami.Units.gridUnit * 1.9)
    readonly property int itemSpacing: Kirigami.Units.smallSpacing
    readonly property int railTopMargin: edgeMargin
    readonly property int railBottomMargin: Kirigami.Units.smallSpacing
}
