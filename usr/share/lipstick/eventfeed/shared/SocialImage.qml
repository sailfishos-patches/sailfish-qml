/****************************************************************************
**
** Copyright (C) 2014-2015 Jolla Ltd.
** Contact: Antti Seppälä <antti.seppala@jollamobile.com>
**
****************************************************************************/
import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.socialcache 1.0

Item {
    id: container

    property url source
    property url fallbackSource: source
    property bool connectedToNetwork
    property SocialImageCache downloader
    property int accountId
    property int expires: 28  // default cache time in days

    property alias fillMode: image.fillMode
    property alias sourceSize: image.sourceSize

    property bool isLandscape: Math.floor(imageImplicitWidth) > Math.floor(imageImplicitHeight)
    property alias imageImplicitWidth: image.implicitWidth
    property alias imageImplicitHeight: image.implicitHeight

    onConnectedToNetworkChanged: {
        if (connectedToNetwork) {
            resolveCachedUrl()
        }
    }
    onSourceChanged: resolveCachedUrl()
    onDownloaderChanged: resolveCachedUrl()

    Rectangle {
        id: placeholderRect
        visible: image.status !== Image.Ready
        color: Theme.highlightColor
        opacity: 0.06
        width: container.width
        height: container.height
    }

    Image {
        id: image
        asynchronous: true
        width: container.width
        height: container.height
        onStatusChanged: {
            if (status === Image.Error) {
                if (container.downloader) {
                    container.downloader.removeFromRecentlyUsed(container.source)
                }
                source = container.fallbackSource
            }
        }
    }

    function resolveCachedUrl() {
        if (downloader && source != "") {
            downloader.imageFile(container.source, container.accountId,
                                 container, container.expires)
        }
    }

    // SocialImageCache will call one of these two methods after the image has been
    // either dowloaded or download fails.
    function imageCached(imageFile) {
        image.source = imageFile
    }

    function downloadError() {
        image.source = container.fallbackSource
    }
}
