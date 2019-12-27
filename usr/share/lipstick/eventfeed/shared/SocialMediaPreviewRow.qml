/****************************************************************************
**
** Copyright (C) 2014-15 Jolla Ltd.
** Contact: Antti Seppälä <antti.seppala@jollamobile.com>
**
****************************************************************************/
import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0
import org.nemomobile.socialcache 1.0

Item {
    id: container

    property var imageList
    property string mediaName
    property int imageCount: imageList ? imageList.length : 0
    property SocialImageCache downloader
    property int accountId
    property bool connectedToNetwork
    property bool highlighted
    property real eventsColumnMaxWidth

    property real _adjustedWidth: width - (imageCount == 0 ? 0 : (imageCount - 1) * imageRow.spacing)
    property real _adjustedCount: Math.min(imageCount, imageRow.columns)
    property real _maxSourceSizeWidth: eventsColumnMaxWidth - (imageCount == 0 ? 0 : (imageCount - 1) * imageRow.spacing)
    property real _sourceSizeWidth: imageCount == 0 ? 0 : Math.max(Theme.itemSizeSmall,
                                                                   _maxSourceSizeWidth / _adjustedCount)
    property real _imageWidth: imageCount == 0 ? 0 : Math.max(Theme.itemSizeSmall,
                                                              _adjustedWidth / _adjustedCount)

    width: parent.width
    height: imageRow.height + (caption.visible ? caption.anchors.topMargin + caption.height : 0)
    visible: imageCount > 0

    Grid {
        id: imageRow
        width: parent.width
        spacing: Theme.paddingSmall
        columns: 4

        Repeater {
            model: container.imageList
            delegate: SocialImage {
                // Landscape pictures: retain picture ratio. Portrait or square: apply square cropping.
                // Either way, only scale down from the original size, not up. Also don't set
                // sourceSize.height as PreserveAspectCrop fillMode would scale the image down to
                // that height, and we want the image to scale to the full width, not the height.
                sourceSize.width: container._sourceSizeWidth
                width: Math.min(imageImplicitWidth, container._imageWidth)
                height: isLandscape ? width * imageImplicitHeight / imageImplicitWidth : width
                fillMode: isLandscape ? Image.Stretch : Image.PreserveAspectCrop

                visible: index < container.imageCount
                source: modelData.url
                downloader: container.downloader
                accountId: container.accountId
                connectedToNetwork: container.connectedToNetwork
                // It is likely that images in feeds are needed for shorter
                // period than avatars, decrease cache time
                expires: 14
            }
        }
    }

    Label {
        id: caption
        anchors {
            top: imageRow.bottom
            topMargin: Theme.paddingSmall
            left: parent.left
            right: parent.right
        }
        visible: container.imageCount === 1 && text.length > 0
        text: container.mediaName
        font.pixelSize: Theme.fontSizeExtraSmall
        color: container.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
    }
}
