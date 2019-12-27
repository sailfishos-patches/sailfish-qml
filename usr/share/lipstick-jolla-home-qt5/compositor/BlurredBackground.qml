import QtQuick 2.1
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

GlassBackground {
    id: glassBackground

    patternItem: null
    backgroundItem: Lipstick.compositor.blurSource || Lipstick.compositor.wallpaper.applicationBackgroundSourceImage
    color: Theme.rgba(Theme.overlayBackgroundColor, 0.65)
    transformItem: null
}
