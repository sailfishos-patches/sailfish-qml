import QtQuick 2.0

QtObject {
    id: wallpaperPath

    // in
    property real contentY
    property real yMarginAtTop
    property real yAtPeekingPosition
    property real yAtSwitcher
    property real yAtBottom
    property real screenHeight
    property real maxVerticalOffset

    // out
    readonly property alias opacity: opacityPath.x
    readonly property alias verticalOffset: wallpaperPath.wallpaperPosition


    // local helpers
    readonly property real wallpaperPosition: -(yMarginAtTop + contentY) / 4
    readonly property real wallpaperCenter: yMarginAtTop + yAtPeekingPosition
    readonly property real wallpaperDistance: yMarginAtTop + yAtBottom


    property PathInterpolator opacityPathInterpolator: PathInterpolator {
        id: opacityPath
        progress: wallpaperPath.contentY / wallpaperPath.yAtBottom
        path: Path {
          startX: 0.4
          PathLine { x: 0.4 }
          PathPercent { value: wallpaperPath.yAtSwitcher / Math.max(2*wallpaperPath.yAtSwitcher, wallpaperPath.yAtBottom) }
          PathLine { x: 1.0 }
          PathPercent { value: 1.0 }
        }
    }
}
