import QtQuick 2.0
import Sailfish.Silica 1.0
import "../main"

GlassBackground {
    id: dimmedBackgroundEffect

    property real offset
    property real distance: width
    property bool relativeDim

    property bool dimmed: { return false }

    property real wallpaperDimOpacity: relativeDim ? Math.max(0, 1.0 - offset / (distance*2/3))
                                                   : 0

    property real _dimOpacity: dimmed ? Theme.opacityHigh : 0.0
    Behavior on _dimOpacity { FadeAnimation { id: dimAnim; property: "_dimOpacity" } }

    opacity: Math.max(dimmedBackgroundEffect._dimOpacity, wallpaperDimOpacity)
    color: Theme.colorScheme == Theme.DarkOnLight
           ? Theme.rgba(Theme.lightPrimaryColor, 0.4)
           : Theme.rgba(Theme.highlightDimmerColor, Theme.highlightBackgroundOpacity)
    patternItem: null
}
