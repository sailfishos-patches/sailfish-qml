import QtQuick 2.2
import com.jolla.lipstick 0.1

Timer {
    id: watcher

    property int count
    property int pid
    property int timeoutAdjustment
    property QtObject launcherItem

    signal startupFailed()

    interval: 2000
    repeat: true

    onTriggered: {
        count++
        if ((pid <= 0 && count == (6 + timeoutAdjustment))
                    || (pid > 0 && (count == (15 + timeoutAdjustment) || JollaSystemInfo.matchingPidForCommand([ pid ], launcherItem.exec, true) != pid))) {
            watcher.startupFailed()
        } else if (count == 1 || pid <= 0) {
            pid = JollaSystemInfo.matchingPidForCommand(null, launcherItem.exec, true)
        }
    }

    onRunningChanged: {
        if (!running) {
            count = 0
            pid = 0
        }
    }
}
