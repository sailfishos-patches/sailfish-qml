import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

PannableLayer {
    id: eventsLayer

    property alias contentItem: content
    property alias overlayItem: overlay

    property real contentY
    property bool menuOpen
    property bool housekeeping
    property bool housekeepingAllowed
    readonly property bool topMenuHousekeeping: Lipstick.compositor.topMenuLayer.housekeeping


    function setHousekeeping(enable) {
        if (enable && !housekeepingAllowed) {
            return
        }
        housekeeping = enable
    }

    function toggleHousekeeping() {
        setHousekeeping(!housekeeping)
    }

    function _autoDisableHousekeeping() {
        if (!visible && (!Lipstick.compositor.homeLayer || !Lipstick.compositor.homeLayer.moving)) {
            housekeeping = false
            if (Lipstick.compositor && Lipstick.compositor.topMenuLayer)
                Lipstick.compositor.topMenuLayer.housekeeping = false
        }
    }

    // Do not allow both events housekeeping and shortcuts housekeeping to be active simultaneously
    onHousekeepingChanged: if (housekeeping) Lipstick.compositor.topMenuLayer.housekeeping = false
    onTopMenuHousekeepingChanged: if (topMenuHousekeeping) housekeeping = false

    statusOffset: Math.min(contentY, statusBar.height + Theme.paddingMedium)
    statusOpacity: menuOpen ? Theme.opacityLow : 1

    onHousekeepingAllowedChanged: {
        if (!housekeepingAllowed && housekeeping) {
            setHousekeeping(false)
        }
    }

    onVisibleChanged: {
        _autoDisableHousekeeping()
    }

    Connections {
        target: Lipstick.compositor.homeLayer
        onMovingChanged: {
            _autoDisableHousekeeping()
        }
    }

    Behavior on statusOpacity {
        FadeAnimation { property: "statusOpacity" }
    }

    Item {
        id: content
        anchors.fill: parent
    }
    Item {
        id: overlay
        anchors.fill: parent
    }
}
