import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

Column {
    id: welcomeFeedItem
    width: parent.width

    property var model: null
    property alias busy: moreButton.busy

    property var _itemModel: null
    property var _nextItemModel: null
    property int _itemType: _itemModel ? _itemModel.itemType : Feed.Unknown

    Connections {
        target: model

        onFeedItemInserted: {
            _nextItemModel = feed
            feedItemAnimation.restart()
        }
    }

    SequentialAnimation {
        id: feedItemAnimation

        FadeAnimation { target: feedItem; to: 0; duration: 250 }
        ScriptAction { script: _itemModel = _nextItemModel }
        FadeAnimation { target: feedItem; to: 1; duration: 250 }
    }

    MoreButton {
        id: moreButton
        width: parent.width
        height: Theme.itemSizeMedium
        enabled: jollaStore.connectionState === JollaStore.Ready
        //: A text for a button that opens the feed (activity) page
        //% "Activity"
        text: qsTrId("jolla-store-li-feed_button")

        onClicked: {
            pageStack.animatorPush(Qt.resolvedUrl("FeedPage.qml"),
                                   { model: welcomeFeedItem.model })
        }

        WelcomeBoxBackground {
            anchors.fill: parent
            z: -1
        }
    }

    BackgroundItem {
        id: feedItem

        x: appGridMargin
        width: parent.width - 2 * appGridMargin
        height: gridItemForSize.height
        visible: _itemModel !== null

        onClicked: {
            if (_itemModel.collection !== "") {
                navigationState.openCategory(_itemModel.collection, ContentModel.TopNew)
            } else {
                navigationState.openApp(_itemModel.appUuid, ApplicationState.Normal)
            }
        }

        AppImage {
            id: appImage
            anchors {
                left: parent.right
                leftMargin: Theme.paddingMedium - gridItemForSize.width
                verticalCenter: parent.verticalCenter
            }
            width: appGridIconSize
            height: appGridIconSize
            image: _itemModel ? _itemModel.icon : ""
        }

        Text {
            id: layoutHelper
            anchors.centerIn: parent
            font.pixelSize: appGridFontSize
            visible: false
            // Three lines of text
            text: "\n\n"
        }

        Column {
            anchors {
                left: appImage.right
                leftMargin: Theme.paddingMedium
                right: parent.right
                rightMargin: Theme.paddingSmall
                top: layoutHelper.top
            }

            Label {
                id: appTitleLabel
                width: parent.width
                color: feedItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: appGridFontSize
                truncationMode: TruncationMode.Fade
                text: _itemModel ? _itemModel.appTitle : ""
            }

            Label {
                id: authorLabel
                width: parent.width
                color: Theme.rgba(Theme.highlightColor, Theme.opacityHigh)
                font.pixelSize: appGridFontSize
                truncationMode: TruncationMode.Fade
                text: _itemModel ? _itemModel.appUserName : ""
            }

            Item {
                // Helper item for matching the vertical alignment of the status icon
                // with the one of the AppGridItem
                width: parent.width
                height: authorLabel.height

                Image {
                    anchors {
                        right: parent.right
                        rightMargin: Theme.paddingSmall
                        verticalCenter: parent.verticalCenter
                    }
                    source: {
                        if (_itemModel) {
                            return _itemModel.appState === ApplicationState.Installed
                                    ? "image://theme/icon-s-installed"
                                    : _itemModel.appState === ApplicationState.Updatable
                                      ? "image://theme/icon-s-update"
                                      : _itemModel.androidApp
                                        ? "image://theme/icon-s-android-label"
                                        : ""
                        } else {
                            return ""
                        }
                    }
                }
            }
        }

        Column {
            anchors {
                left: parent.left
                leftMargin: Theme.paddingSmall
                // Make the right margin align with the right edge of the "status icon"
                // on the app grid
                right: appImage.left
                rightMargin: appGridSpacing + Theme.paddingSmall + Theme.paddingMedium
                top: layoutHelper.top
            }

            Label {
                id: feedTitleLabel
                anchors {
                    left: parent.left
                    right: parent.right
                    rightMargin: Theme.paddingSmall + icon.width
                }
                color: feedItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: appGridFontSize
                truncationMode: TruncationMode.Fade
                horizontalAlignment: Text.AlignRight
                text: _itemModel ? _itemModel.title : ""

                Image {
                    id: icon

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.right
                        leftMargin: Theme.paddingSmall
                    }
                    source: {
                        var itemType = _itemModel ? _itemModel.itemType : Feed.Unknown
                        var src = "image://theme/icon-"
                        if (itemType === Feed.Like) {
                            src += "s-like"
                        } else if (itemType === Feed.Comment) {
                            src += "s-chat"
                        } else if (itemType === Feed.New) {
                            src += "s-new"
                        } else {
                            src += "m-jolla"
                        }
                        return src
                    }
                }
            }

            Label {
                id: feedTextLabel
                visible: text !== "" && _itemModel && _itemModel.itemType !== Feed.Like
                width: parent.width
                color: Theme.highlightColor
                font.pixelSize: appGridFontSize
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignRight
                maximumLineCount: 2
                text: _itemModel ? _itemModel.description : ""
            }
        }
    }

    Item { width: 1; height: Theme.paddingMedium; visible: !busy }
}
