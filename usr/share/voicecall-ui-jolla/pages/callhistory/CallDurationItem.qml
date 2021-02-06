import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    property alias highlighted: label.highlighted
    spacing: Theme.paddingSmall
    HighlightImage {
        source: "image://theme/icon-s-duration"
        highlighted: label.highlighted
        anchors.verticalCenter: parent.verticalCenter
    }
    Label {
        id: label
        property int duration: model.endTime && model.startTime
                               ? (model.endTime.valueOf() - model.startTime.valueOf()) / 1000
                               : 0

        color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
        font.pixelSize: Theme.fontSizeSmall
        anchors.verticalCenter: parent.verticalCenter
        text: Format.formatDuration(duration, duration >= 3600 ? Formatter.DurationLong : Formatter.DurationShort)
    }
}
