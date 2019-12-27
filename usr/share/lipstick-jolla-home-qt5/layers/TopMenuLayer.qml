import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1

EdgeLayer {
    id: topMenuLayer

    property bool housekeeping
    property bool closeFromEdge
    property Item topMenu
    readonly property rect exposedArea: topMenu ? Qt.rect(topMenu.exposedArea.x, topMenu.exposedArea.y,
                                                          topMenu.exposedArea.width, topMenu.exposedArea.height)
                                                : Qt.rect(0, 0, 0, 0)

    signal toggleActive()

    peekFilter {
        enabled: Lipstick.compositor.systemInitComplete
        onTopActiveChanged: closeFromEdge = peekFilter.topActive
        onLeftActiveChanged: closeFromEdge = peekFilter.leftActive
        onRightActiveChanged: closeFromEdge = peekFilter.rightActive
    }

    childrenOpaque: false
    objectName: "topMenuLayer"

    edge: PeekFilter.Top
    hintHeight: topMenu ? topMenu.itemSize * 2 : 0
    hintDuration: 600

    function show() {
        if (!active) {
            toggleActive()
        }
    }

    function hide() {
        if (active) {
            toggleActive()
        }
    }
}
