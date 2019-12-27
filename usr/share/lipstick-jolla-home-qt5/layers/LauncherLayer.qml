import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1

EdgeLayer {
    id: launcherLayer

    // Show launcher above alarms
    property bool allowed
    property bool closedFromBottom

    peekFilter {
        enabled: Lipstick.compositor.systemInitComplete
        onGestureTriggered: closedFromBottom = peekFilter.bottomActive
    }

    function hide() {
        if (window && window == Lipstick.compositor.topmostWindow)
            Lipstick.compositor.setCurrentWindow(Lipstick.compositor.obscuredWindow)
    }


    onExposedChanged: closedFromBottom = false

    childrenOpaque: false
    objectName: "launcherLayer"

    edge: PeekFilter.Bottom
    hintHeight: Theme.iconSizeLauncher * 2 + (Screen.sizeCategory >= Screen.Large ? Theme.paddingLarge*4 : 0)
    hintDuration: 600
}
