import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

PannableLayer {
    id: switcherLayer

    property alias contentItem: content
    property alias overlayItem: overlay

    readonly property bool housekeeping: Desktop.instance &&
                                         Desktop.instance.switcher &&
                                         Desktop.instance.switcher.housekeeping

    function setHousekeeping(enable) {
        if (Desktop.instance && Desktop.instance.switcher) {
            Desktop.instance.switcher.housekeeping = enable
        }
    }

    property real contentY
    property bool menuOpen

    statusOffset: Math.min(contentY, statusBar.height + Theme.paddingMedium)
    statusOpacity: menuOpen ? Theme.opacityLow : 1

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
