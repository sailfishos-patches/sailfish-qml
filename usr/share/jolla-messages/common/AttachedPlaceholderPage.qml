import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: true
    }
}
