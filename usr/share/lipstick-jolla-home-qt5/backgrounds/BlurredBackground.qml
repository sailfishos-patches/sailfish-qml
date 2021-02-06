import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0
import org.nemomobile.lipstick 0.1
import "materials" as M

Background {
    id: background

    property color color: Theme.rgba(palette.overlayBackgroundColor, 0.65)

    sourceItem: Lipstick.compositor.blurSource
                || Lipstick.compositor.wallpaper.applicationWallpaperItem
    material: M.BlurMaterial
}

