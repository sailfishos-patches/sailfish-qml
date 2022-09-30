import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0

ThemeBackground {
    anchors.fill: parent

    sourceItem: wallpaper
    patternItem: texture
    transformItem: mainWindow.rotationItem

    ThemeWallpaper {
        id: wallpaper

        source: Theme._homeBackgroundImage
        visible: false
    }

    Image {
        id: texture

        source: Theme._patternImage
        visible: false
    }
}
