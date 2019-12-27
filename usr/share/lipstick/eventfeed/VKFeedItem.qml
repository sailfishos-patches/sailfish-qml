import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0
import "shared"

SocialMediaFeedItem {
    id: item
    height: Math.max(content.height, avatar.height) + Theme.paddingMedium * 3
    width: parent.width
    avatarSource: model.icon

    property variant imageList
    property bool isRepost: repostType.visible
    property string formattedRepostTime

    onRefreshTimeCountChanged: formattedRepostTime = Format.formatDate(model.repostTimestamp, Format.DurationElapsed)

    Column {
        id: content
        x: item.avatar.width + Theme.paddingMedium
        y: item.topMargin
        width: parent.width - (item.avatar.width + Theme.paddingMedium*2)

        SocialMediaPreviewRow {
            downloader: item.downloader
            imageList: item.imageList
            connectedToNetwork: item.connectedToNetwork
            eventsColumnMaxWidth: item.eventsColumnMaxWidth - item.avatar.width
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            opacity: .6
            text: model.name
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.primaryColor
            textFormat: Text.PlainText
        }

        Text {
            id: repostType
            width: parent.width
            elide: Text.ElideRight
            opacity: .6
            text: item.repostTypeText(model.repostType)
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.primaryColor
            visible: text !== ""
            textFormat: Text.PlainText
        }

        LinkedText {
            width: parent.width
            maximumLineCount: 15
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeSmall
            shortenUrl: true
            color: item.pressed ? Theme.highlightColor : Theme.primaryColor
            linkColor: Theme.highlightColor
            plainText: model.body
            visible: plainText !== ""
        }

        Text {
            width: parent.width
            maximumLineCount: 1
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeSmall
            text: item.formattedTime
        }

        Column {
            width: parent.width
            visible: item.isRepost
            spacing: Theme.paddingSmall

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            Item {
                width: parent.width
                height: repostIcon.height

                Image {
                    id: repostIcon
                    source: "image://theme/icon-s-repost" + (item.highlighted ? "?" + Theme.highlightColor : "")
                }

                Text {
                    anchors {
                        left: repostIcon.right
                        leftMargin: Theme.paddingMedium
                        right: parent.right
                        verticalCenter: repostIcon.verticalCenter
                    }
                    elide: Text.ElideRight
                    opacity: .6
                    text: model.repostOwnerName
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                    textFormat: Text.PlainText
                }
            }

            Item {
                width: 1
                height: Theme.paddingSmall
            }

            SocialMediaPreviewRow {
                downloader: item.downloader
                imageList: model.repostImages
                connectedToNetwork: item.connectedToNetwork
                eventsColumnMaxWidth: item.eventsColumnMaxWidth - item.avatar.width
            }

            LinkedText {
                width: parent.width
                maximumLineCount: 15
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                shortenUrl: true
                color: item.pressed ? Theme.highlightColor : Theme.primaryColor
                linkColor: Theme.highlightColor
                plainText: model.repostText
                visible: plainText !== ""
            }

            Text {
                text: item.formattedRepostTime
                maximumLineCount: 1
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                color: item.highlighted ? Theme.secondaryHighlightColor : Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                textFormat: Text.PlainText
            }
        }
    }

    function repostTypeText(repostType) {
        if (repostType !== "") {
            switch (repostType) {
            case "link":
                //: User shared a link in VK
                //% "Shared link"
                return qsTrId("lipstick-jolla-home-la-vk_shared_link")
            case "video":
                //: User shared a video in VK
                //% "Shared video"
                return qsTrId("lipstick-jolla-home-la-vk_shared_video")
            case "photo":
                //: User shared a photo in VK
                //% "Shared photo"
                return qsTrId("lipstick-jolla-home-la-vk_shared_photo")
            }

            //: User shared a post in VK
            //% "Shared post"
            return qsTrId("lipstick-jolla-home-la-vk_shared_post")
        }

        return ""
    }
}
