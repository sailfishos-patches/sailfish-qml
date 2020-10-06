import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    anchors.horizontalCenter: parent.horizontalCenter
    color: Theme.highlightColor
    linkColor: Theme.primaryColor
    width: parent.width - 2*Theme.horizontalPageMargin
    wrapMode: Text.WordWrap
    onLinkActivated: Qt.openUrlExternally(link)
}
