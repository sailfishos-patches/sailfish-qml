import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    property bool reallyWideScreen: (Screen.height / Screen.width) >= 2.0
    // Position bottom controls so that they are vertically centered
    // inside the bottom area below the 4:3 aspect ratio viewport
    property int smallMargin: Theme.paddingLarge + Theme.paddingMedium
    property int largeMargin: Math.max(smallMargin,
                                       (Screen.height - 4/3*Screen.width - (reallyWideScreen ? Theme.itemSizeLarge : 0))/2 - height/2)
    anchors {
        topMargin: smallMargin
        leftMargin: smallMargin
        rightMargin: isPortrait ? smallMargin : largeMargin
        bottomMargin: isPortrait ? largeMargin : smallMargin
    }
    width: Theme.itemSizeMedium
    height: Theme.itemSizeMedium
}
