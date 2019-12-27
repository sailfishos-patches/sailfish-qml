import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property bool showDetails
    readonly property bool twoRows: contentWidth > width
    readonly property int contentWidth: remoteUidLabel.implicitWidth + columnSpacing + detailsRow.implicitWidth
    readonly property int columnSpacing: Theme.paddingSmall
    readonly property bool hasVisibleContent: !privateNumber || showDetails

    readonly property bool occurredToday: {
        var date = model.startTime
        var now = main.today
        return date.getFullYear() === now.getFullYear() && date.getMonth() === now.getMonth() && date.getDate() === now.getDate()
    }

    width: parent.width - 2 * Theme.horizontalPageMargin
    height: twoRows ? remoteUidLabel.height + detailsRow.height
                    : remoteUidLabel.height
    anchors.horizontalCenter: parent.horizontalCenter

    Label {
        id: remoteUidLabel
        x: twoRows ? 0 : (parent.width - parent.contentWidth)/2
        color: palette.secondaryHighlightColor
        font.pixelSize: Theme.fontSizeSmall
        width: Math.min(parent.width, implicitWidth)
        anchors.horizontalCenter: twoRows ? parent.horizontalCenter : undefined
        verticalAlignment: Text.AlignVCenter
        height: Math.max(detailsRow.height, implicitHeight)
        truncationMode: TruncationMode.Fade
        text: model.remoteUid
    }

    Row {
        id: detailsRow
        spacing: Theme.paddingSmall
        anchors {
            left: twoRows ? undefined : remoteUidLabel.right
            leftMargin: columnSpacing
            horizontalCenter: twoRows ? parent.horizontalCenter : undefined
            top: twoRows ? remoteUidLabel.bottom : parent.top
        }

        HighlightImage {
            visible: !occurredToday && showDetails
            source: "image://theme/icon-s-time"
            color: palette.highlightColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Label {
            visible: !occurredToday && showDetails
            color: palette.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeSmall
            anchors.verticalCenter: parent.verticalCenter
            text: Format.formatDate(model.startTime, Formatter.TimeValue)
        }

        CallDurationItem {
            visible: !model.isMissedCall && showDetails
            anchors.verticalCenter: parent.verticalCenter
            highlighted: true
        }
    }
}
