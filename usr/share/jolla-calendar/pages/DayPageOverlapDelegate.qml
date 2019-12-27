import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    Rectangle {
        x: Theme.paddingSmall
        y: Theme.paddingSmall
        width: parent.width - Theme.paddingSmall - Theme.horizontalPageMargin + Theme.paddingLarge
        height: parent.height - 2 * Theme.paddingSmall
        color: Theme.secondaryHighlightColor
        radius: 3
        Label {
            id: description
            x: Theme.paddingSmall
            y: Theme.paddingSmall
            width: parent.width - 2 * Theme.paddingSmall
            text: overlapTitles
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            visible: parent.height >= 2 * (Theme.paddingSmall + overview.height)
            height: parent.height - overview.height
        }
        Label {
            id: overview
            anchors.horizontalCenter: parent.horizontalCenter
            y: description.visible ? (parent.height - overview.height - Theme.paddingSmall)
                                   : ((parent.height - overview.height) / 2)
            //: label on hour view for too many overlapping events to be shown
            //% "See overlapping events"
            text: qsTrId("calendar-la-overlapping_events")
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                pageStack.animatorPush("DayOverlapPage.qml", { model: overlapEvents, date: dayPage.date })
            }
        }
    }
}
