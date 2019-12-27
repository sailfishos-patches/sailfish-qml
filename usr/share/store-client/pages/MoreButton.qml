import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: morePanel

    property alias text: moreLabel.text
    property int horizontalMargin: Theme.horizontalPageMargin
    property alias busy: busyIndicator.running

    height: Theme.itemSizeSmall

    Label {
        id: moreLabel
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: (morePanel.enabled || busy) ? moreImage.left : parent.right
            rightMargin: (morePanel.enabled || busy) ? Theme.paddingMedium : horizontalMargin
            verticalCenter: parent.verticalCenter
        }
        horizontalAlignment: Text.AlignRight
        truncationMode: TruncationMode.Fade
        color: (morePanel.highlighted || !morePanel.enabled)
               ? Theme.highlightColor
               : Theme.primaryColor
    }

    Image {
        id: moreImage
        anchors {
            right: parent.right
            rightMargin: horizontalMargin
            verticalCenter: parent.verticalCenter
        }
        visible: morePanel.enabled && !busy
        source: "image://theme/icon-m-right?"
                + (morePanel.highlighted ? Theme.highlightColor : Theme.primaryColor)
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: moreImage
        size: BusyIndicatorSize.Small
    }
}
