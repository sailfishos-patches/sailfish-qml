import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0

Item {
    id: root

    property date date: new Date
    property int currentIndex
    property string currentView: tabs.model.get(currentIndex).view
    property alias title: titleLabel.text
    property alias description: descriptionLabel.text
    property bool animated: true
    property alias model: tabs.model

    signal dateClicked()

    height: Screen.sizeCategory > Screen.Medium ? Theme.itemSizeLarge : Theme.itemSizeMedium

    Item {
        height: parent.height
        x: Theme.horizontalPageMargin
        Row {
            id: tabRow
            height: parent.height
            Repeater {
                id: tabs
                SilicaMouseArea {
                    width: icon.width + Theme.paddingLarge
                    height: icon.height
                    anchors.verticalCenter: parent.verticalCenter
                    HighlightImage {
                        id: icon
                        source: model.icon
                        anchors.centerIn: parent
                        highlighted: parent.highlighted || root.currentIndex == model.index
                    }
                    onClicked: root.currentIndex = model.index
                }
            }
        }
        Rectangle {
            parent: root.currentIndex < tabs.count ? tabs.itemAt(root.currentIndex) : null
            width: parent ? parent.width : 0
            height: Theme._lineWidth
            anchors {
                bottom: parent ? parent.bottom : undefined
                bottomMargin: -Theme.paddingSmall
            }
            color: Theme.highlightColor
        }
    }

    BackgroundItem {
        id: dateItem
        anchors.right: root.right
        height: parent.height
        width: root.width - Theme.horizontalPageMargin - tabRow.width - Theme.paddingLarge
        onClicked: root.dateClicked()
        FlippingLabel {
            id: titleLabel
            animate: root.animated
            color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
            fontSize: Screen.sizeCategory > Screen.Medium ? Theme.fontSizeExtraLarge : Theme.fontSizeLarge
            transformOrigin: Item.Right
            scale: Math.min(1., (dateItem.width - anchors.rightMargin - Theme.paddingLarge) / width)
            anchors {
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                bottom: parent.verticalCenter
                bottomMargin: descriptionLabel.text.length > 0 ? -Theme.paddingSmall : -height / 2
            }
            Behavior on anchors.bottomMargin { SmoothedAnimation { duration: 1000 } }
        }
        FlippingLabel {
            id: descriptionLabel
            animate: root.animated
            color: parent.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            fontSize: Screen.sizeCategory > Screen.Medium ? Theme.fontSizeMedium : Theme.fontSizeSmall
            transformOrigin: Item.Right
            scale: Math.min(1., (dateItem.width - anchors.rightMargin - Theme.paddingLarge) / width)
            anchors {
                topMargin: Theme.paddingSmall
                top: parent.verticalCenter
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
            }
        }
    }
}
