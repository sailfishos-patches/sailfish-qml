import QtQuick 2.0
import Sailfish.Silica 1.0

/* Image representing an app by cover or icon.
 * If the image is not set or could not be loaded, a fallback will be used.
 */
StoreImage {
    property string emptyFallback: "image://theme/icon-store-app-default"

    opacity: imageStatus === Image.Loading ? 0.1 : 1

    // TODO: Remove this workaround!
    _scaleDownWorkaround: sourceSize.height > height || width === Theme.iconSizeLauncher

    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    // don't show the empty fallback immediately while loading an image,
    // because this would cause flickering when showing images that are
    // available immediately
    Timer {
        id: emptyFallbackTimer
        interval: 500
        onTriggered: {
            if (_storeStatus === Image.Loading || imageStatus === Image.Null) {
                source = emptyFallback
            }
        }
    }

    Component.onCompleted: {
        emptyFallbackTimer.restart()
    }

    onImageStatusChanged: {
        if (imageStatus === Image.Error) {
            source = emptyFallback
        }
    }

    onImageChanged: {
        emptyFallbackTimer.restart()
    }
}
