import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

Layer {
    id: lockScreenLayer

    property bool screenIsLocked
    property bool deviceIsLocked
    property bool pendingPinQuery
    property bool lockSuppressedByPeek
    property bool showingLockCodeEntry
    property real notificationOpacity: showNotifications ? (lipstickSettings.lowPowerMode ? Theme.opacityOverlay : 1.0) : 0.0
    property string notificationAnimation
    property string unlockReason

    readonly property bool locked: screenIsLocked || deviceIsLocked || Lipstick.compositor.cameraLayer.active

    // Text color of items that are shown in low power mode
    property color textColor: lipstickSettings.lowPowerMode ? Theme.highlightColor : Theme.primaryColor

    // Controlled by LockScreen.
    property bool showNotifications

    signal cacheWindow(Item window)

    objectName: "lockScreenLayer"

    enabled: active
             && !Lipstick.compositor.topMenuLayer.active    // don't pan lockscreen views when top menu is visible

    onLockedChanged: {
        if (locked || notificationAnimation === "animated") {
            notificationAnimation = ""
        }
        if (!locked && !peekingAtHome) {
            close()
        }
    }
    onExposedChanged: notificationAnimation = ""

    onAboutToClose: cacheWindow(window)
}
