import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    Image {
        anchors.fill: parent
        clip: true
        source: coverImage
        fillMode: Image.PreserveAspectCrop
        sourceSize { width: width; height: height }
        smooth: true
        asynchronous: true

        Rectangle {
            anchors.fill: parent
            color: Theme.rgba(Theme.highlightDimmerColor, Theme.opacityHigh)
        }

        BusyIndicator {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: displayNameLabel.lineCount === 2 ? -displayNameLabel.contentHeight / 2 : 0
            size: BusyIndicatorSize.Medium
            running: true
        }
    }
}
