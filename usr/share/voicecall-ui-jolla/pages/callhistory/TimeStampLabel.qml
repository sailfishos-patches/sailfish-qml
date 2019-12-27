import QtQuick 2.6
import Sailfish.Silica 1.0

Label {
    property int formatType: Formatter.TimeValue
    text: Format.formatDate(time, formatType)
    font.pixelSize: Theme.fontSizeSmall
    color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
    leftPadding: Theme.paddingMedium
    visible: dateColumnVisible
}
