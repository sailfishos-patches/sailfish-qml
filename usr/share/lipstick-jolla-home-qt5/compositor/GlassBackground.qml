import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as SilicaPrivate
import org.nemomobile.lipstick 0.1

SilicaPrivate.GlassBackgroundBase {
    id: glassBackground

    patternItem: Lipstick.compositor.wallpaper.applicationBackgroundOverlayImage
    backgroundItem: Lipstick.compositor.wallpaper.applicationBackgroundSourceImage
    transformItem: Lipstick.compositor.wallpaper.transformItem

    color: Theme._coverOverlayColor

    blending: true
}
