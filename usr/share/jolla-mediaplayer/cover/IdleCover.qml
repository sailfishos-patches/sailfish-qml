import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.mediaplayer 1.0

Item {
    property bool sourcesReady
    property url largeAlbumArt
    property url leftSmallAlbumArt
    property url rightSmallAlbumArt

    property bool _leftSmall: leftSmallAlbumArt != ""
    property bool _rightSmall: rightSmallAlbumArt != ""

    onSourcesReadyChanged: {
        // sourcesReady changes after _leftSmall and _rightSmall have changed.
        // Thus, image sizes have been figured out before loading images.
        if (sourcesReady) {
            largeThumbnail.source = largeAlbumArt

            if (_leftSmall) {
                leftThumbnail.source = leftSmallAlbumArt
            }

            if (_rightSmall) {
                rightThumbnail.source = rightSmallAlbumArt
            }
        }
    }

    Image {
        id: largeThumbnail

        width:  parent.width
        height: _leftSmall || _rightSmall ? width :  parent.height
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectCrop
    }

    Image {
        id: leftThumbnail

        anchors.top: largeThumbnail.bottom
        width: _rightSmall ? parent.width / 2 : parent.width
        height: parent.height - largeThumbnail.height
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectCrop
        opacity: Theme.opacityLow
        visible: _leftSmall
    }

    Image {
        id: rightThumbnail

        anchors {
            top: leftThumbnail.top
            left: leftThumbnail.right
        }
        width: parent.width / 2
        height: parent.height - largeThumbnail.height
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectCrop
        opacity: Theme.opacityLow
        visible: _rightSmall
    }
}
