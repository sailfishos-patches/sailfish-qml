import QtQuick 2.0
import Sailfish.Silica 1.0

Button {
    height: Theme.itemSizeLarge
    anchors.horizontalCenter: parent.horizontalCenter
    property int bottomMargin: isPortrait ? Math.round(Screen.height/30) : 0
}
