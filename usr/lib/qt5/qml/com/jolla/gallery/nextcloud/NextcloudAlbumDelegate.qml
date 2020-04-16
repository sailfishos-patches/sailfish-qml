/****************************************************************************************
**
** Copyright (C) 2019 Open Mobile Platform LLC
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.gallery 1.0
import com.jolla.gallery.nextcloud 1.0

BackgroundItem {
    id: root

    property int accountId
    property string userId
    property string albumId
    property string albumName
    property string albumThumbnailPath
    property int photoCount

    height: image.height

    HighlightImage {
        id: image

        width: Theme.itemSizeExtraLarge
        height: width
        sourceSize.width: width
        sourceSize.height: width
        source: albumThumbnailPath.length ? albumThumbnailPath : "image://theme/icon-l-nextcloud"
        fillMode: albumThumbnailPath.length ? Image.PreserveAspectCrop : Image.PreserveAspectFit
        clip: true
        highlighted: albumThumbnailPath.length === 0 && root.highlighted
        opacity: albumThumbnailPath.length && root.highlighted ? Theme.opacityHigh : 1
    }

    NextcloudImageDownloader {
        id: imageDownloader

        accountId: root.accountId
        userId: root.userId
        albumId: root.albumId

        imageCache: albumThumbnailPath.length === 0
                    ? NextcloudImageCache
                    : null
        downloadThumbnail: true
    }

    Column {
        id: column

        anchors {
            left: image.right
            leftMargin: Theme.paddingLarge
            right: parent.right
            rightMargin: Theme.paddingMedium
            verticalCenter: image.verticalCenter
        }

        Label {
            id: titleLabel
            width: parent.width
            height: text.length > 0 ? implicitHeight : 0
            text: albumName
            truncationMode: TruncationMode.Fade
        }

        Label {
            id: subtitleLabel
            width: parent.width

            //: Photos count for Nextcloud album
            //% "%n photos"
            text: qsTrId("jolla_gallery_nextcloud-album_photo_count", photoCount)
            font.pixelSize: Theme.fontSizeSmall
            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            truncationMode: TruncationMode.Fade
        }
    }
}
