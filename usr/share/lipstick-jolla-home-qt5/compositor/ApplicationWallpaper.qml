import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

Wallpaper {
    id: wallpaper

    // All properties are applied to the rasterized texture. Changing it
    // means updating the texture and is thus very expensive. So don't go
    // animating them.
    textureSize: Qt.size(isLegacyWallpaper ? Screen.width : Screen.height, Screen.height)
    effect: "glass"
    overlayColor: Theme._wallpaperOverlayColor
    source: Theme.backgroundImage
}
