import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import Sailfish.Lipstick 1.0
import com.jolla.lipstick 0.1
import "../main"

StackLayer {
    id: appLayer

    readonly property int pendingWindowId: contentItem.lastItem && contentItem.lastItem != window
                ? contentItem.lastItem.window.windowId
                : 0

    function clearPendingWindows() {
        var head
        while ((head = contentItem.lastItem) && head != window) { head.parent = null }
    }

    objectName: "appLayer"
    exclusive: !Desktop.startupWizardRunning
    onQueueWindow: {
        if (Desktop.startupWizardRunning) {
            if (JollaSystemInfo.matchingPidForCommand(window.window.processId, '/usr/bin/jolla-startupwizard', true) !== -1
                        || JollaSystemInfo.matchingPidForCommand(window.window.processId, '/usr/bin/sailfish-browser', true) !== -1) {
                contentItem.appendItem(window)
            }
        } else if (!Desktop.instance.switcher.checkMinimized(window.window.windowId)) {
            contentItem.appendItem(window)
        }
    }
}
