import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    id: nameLabel

    property bool tooLongToCenter: false // needed to break binding loop
    property bool center: false

    function canCenter() {
        if (paintedWidth > width && !tooLongToCenter) {
            tooLongToCenter = true
        } else if (paintedWidth <= width && tooLongToCenter) {
            tooLongToCenter = false
        }
    }

    color: Theme.primaryColor
    font.pixelSize: Theme.fontSizeMedium
    horizontalAlignment: center && !tooLongToCenter ? Text.AlignHCenter : Text.AlignLeft
    onPaintedWidthChanged: canCenter()
    onWidthChanged: canCenter()
    truncationMode: TruncationMode.Fade
}
