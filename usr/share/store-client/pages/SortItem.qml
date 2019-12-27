import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

BackgroundItem {
    property alias text: sortLabel.text

    Label {
        id: sortLabel
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }
        font.pixelSize: Theme.fontSizeMedium
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
        truncationMode: TruncationMode.Fade
    }
}
