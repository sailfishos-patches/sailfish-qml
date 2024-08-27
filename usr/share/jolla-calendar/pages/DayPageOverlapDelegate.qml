import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root
    property alias fontSize: description.font.pixelSize
    property bool oneLiner: true

    Rectangle {
        x: Theme.paddingSmall
        y: Theme.paddingSmall
        width: parent.width - Theme.paddingSmall - Theme.horizontalPageMargin + Theme.paddingLarge
        height: parent.height - 2 * Theme.paddingSmall
        color: Theme.secondaryHighlightColor
        radius: Theme.paddingSmall / 3
        Label {
            id: description
            x: Theme.paddingSmall
            width: parent.width - 2 * Theme.paddingSmall
            text: overlapTitles.join(Format.listSeparator)
            wrapMode: Text.Wrap
            elide: oneLiner ? Text.ElideRight : Text.ElideNone
            visible: height > 0
            height: Math.min(implicitHeight, parent.height - overview.height - Theme.paddingLarge)
        }
        OpacityRampEffect {
            enabled: !oneLiner && description.visible
                && description.implicitHeight > description.height
            direction: OpacityRamp.TopToBottom
            sourceItem: description
            slope: Math.max(1, description.height / Theme.paddingLarge)
            offset: 1 - 1 / slope
        }
        Label {
            id: overview

            width: Math.min(parent.width - 2 * Theme.paddingSmall, implicitWidth)
            truncationMode: oneLiner ? TruncationMode.Fade : TruncationMode.None
            wrapMode: oneLiner ? Text.NoWrap : Text.Wrap
            clip: !oneLiner
            height: Math.min(implicitHeight, parent.height)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            //: label on hour view for too many overlapping events to be shown
            //% "See overlapping events"
            text: qsTrId("calendar-la-overlapping_events")
            font.pixelSize: description.font.pixelSize
        }
        OpacityRampEffect {
            enabled: !oneLiner
                && overview.implicitHeight > overview.height
            direction: OpacityRamp.TopToBottom
            sourceItem: overview
            slope: Math.max(1, overview.height / Theme.paddingLarge)
            offset: 1 - 1 / slope
        }
    }
    onClicked: {
        pageStack.animatorPush("DayOverlapPage.qml", { model: overlapEvents, date: date })
    }
}
