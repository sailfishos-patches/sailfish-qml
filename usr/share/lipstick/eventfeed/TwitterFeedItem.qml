/****************************************************************************
 **
 ** Copyright (C) 2014 - 2017 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0
import "shared"

SocialMediaFeedItem {
    id: item

    property variant imageList
    property int likeCount
    property int commentCount
    property int retweetCount

    property string _retweeter: model.retweeter

    avatar.y: item._retweeter.length > 0
              ? topMargin + retweeterIcon.height + Theme.paddingSmall
              : topMargin
    contentHeight: Math.max(content.y + content.height, avatar.y + avatar.height) + bottomMargin
    topMargin: item._retweeter.length > 0 ? Theme.paddingMedium : Theme.paddingLarge
    userRemovable: false

    Image {
        id: retweeterIcon
        anchors {
            right: avatar.right
            top: parent.top
            topMargin: item.topMargin
        }
        visible: item._retweeter.length > 0
        source: "image://theme/icon-s-retweet" + (item.highlighted ? "?" + Theme.highlightColor : "")
    }

    Text {
        anchors {
            left: content.left
            right: content.right
            verticalCenter: retweeterIcon.verticalCenter
        }
        elide: Text.ElideRight
        font.pixelSize: Theme.fontSizeExtraSmall
        color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        textFormat: Text.PlainText
        visible: text.length > 0

        text: item._retweeter.length > 0
                //: Shown above a tweet that is a retweet of somebody else's tweet. %1 = name of user who is retweeting
                //% "%1 retweeted"
              ? qsTrId("lipstick-jolla-home-la-retweeted_by").arg(item._retweeter)
              : ""
    }

    Column {
        id: content
        anchors {
            left: avatar.right
            leftMargin: Theme.paddingMedium
            top: avatar.top
        }
        width: parent.width - x

        Label {
            width: parent.width
            truncationMode: TruncationMode.Fade
            text: model.name
            color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
            textFormat: Text.PlainText
        }

        Label {
            width: parent.width
            truncationMode: TruncationMode.Fade
            text: "@" + model.screenName
            font.pixelSize: Theme.fontSizeSmall
            color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            textFormat: Text.PlainText
        }

        LinkedText {
            width: parent.width
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeSmall
            shortenUrl: true
            color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
            linkColor: Theme.highlightColor
            plainText: model.body
        }

        Text {
            width: parent.width
            height: previewRow.visible ? implicitHeight + Theme.paddingMedium : implicitHeight    // add padding below
            maximumLineCount: 1
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            text: item.formattedTime
            textFormat: Text.PlainText
        }

        SocialMediaPreviewRow {
            id: previewRow
            width: parent.width + Theme.horizontalPageMargin   // extend to right edge of notification area
            imageList: item.imageList
            downloader: item.downloader
            accountId: item.accountId
            connectedToNetwork: item.connectedToNetwork
            highlighted: item.highlighted
            eventsColumnMaxWidth: item.eventsColumnMaxWidth - item.avatar.width
        }
    }
}
