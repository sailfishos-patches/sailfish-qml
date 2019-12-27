import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

// Adapted from ui-lipstick-jolla-home/qml/compositor/ApplicationWallpaper.qml
Item {
    id: wallpaper

    property int _dim: Math.max(width, height)

    anchors.fill: parent

    Item {
        id: rotationItem

        anchors.centerIn: parent
        rotation: hwcImage.isLegacyWallpaper ? 0 : wallpaper.rotation

        Behavior on rotation {
            RotationAnimator {
                direction: RotationAnimation.Shortest
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        HwcImage {
            id: hwcImage

            property bool isLegacyWallpaper: width !== height

            anchors.centerIn: parent
            asynchronous: true

            // All properties are applied to the rasterized texture. Changing it
            // means updating the texture and is thus very expensive. So don't go
            // animating them.
            textureSize: Qt.size(isLegacyWallpaper ? wallpaper.width : _dim, _dim)
            effect: "glass"
            overlayColor: Qt.rgba(0, 0, 0, Theme.opacityHigh);
            pixelRatio: Theme.pixelRatio
            rotationHandler: rotationItem
            source: Theme.backgroundImage
        }
    }
}
