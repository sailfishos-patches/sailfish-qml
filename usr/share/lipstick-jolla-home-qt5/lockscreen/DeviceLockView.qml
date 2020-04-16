/****************************************************************************
**
** Copyright (c) 2015 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.lipstick 0.1
import com.jolla.settings.system 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.devicelock 1.0
import org.nemomobile.ngf 1.0
import org.nemomobile.lipstick 0.1

DeviceLockInput {
    id: pininput

    acceptTitle: enterSecurityCode
    subTitleText: Lipstick.compositor.lockScreenLayer.unlockReason || descriptionText

    //: This will be replaced by an icon.
    //% "OK"
    confirmText: qsTrId("lipstick-jolla-home-bt-devicelock_ok")
    showCancelButton: false

    // Don't show emergency call button if device has no voice capability, in case something happen and
    // the value is undefined show it since this is critical functionality
    showEmergencyButton: Desktop.simManager.enabledModems.length > 0 || !Desktop.simManager.ready
    focus: !Desktop.startupWizardRunning

    Timer {
        id: resetTimer
        interval: 300
        onTriggered: {
            pininput.titleText = pininput.enterSecurityCode
            pininput.lastChance = false
            pininput.emergency = false
            pininput._resetView()
        }
    }

    // Don't remove tk_lock via DeviceLockAuthenticationInput on happy path.
    // Both tk_lock and device lock must be handled through system bus / dbus daemon so
    // that mce, lipstick, and device lock stay in sync.
    authenticationInput: DeviceLockAuthenticationInput {
        id: agent

        readonly property bool unlocking: registered
                    && Desktop.deviceLockState >= DeviceLock.Locked && Desktop.deviceLockState < DeviceLock.Undefined
                    && Lipstick.compositor.lockScreenLayer.exposed

        // Don't play feedback sound or transition to the code entry view on authentication
        // starting.
        property bool suppressFeedback

        signal reset()

        registered: Lipstick.compositor.visible && !Desktop.startupWizardRunning

        active: Lipstick.compositor.lockScreenLayer.active && Lipstick.compositor.visible

        onUnlockingChanged: {
            if (unlocking) {
                DeviceLock.unlock()
            } else {
                DeviceLock.cancel()
            }
        }

        onFeedback: {
            if (!suppressFeedback && DeviceLock.state === DeviceLock.Locked) {
                unlockFailedEvent.play()
                Lipstick.compositor.unlock()    // If the lock screen was visible animate to device lock.
            }
        }

        onAuthenticationStarted: {
            reset()
            suppressFeedback = true
            agent.feedback(feedback, data)
            suppressFeedback = false
        }

        onAuthenticationUnavailable: {
            reset()
            agent.error(error, data)
            Lipstick.compositor.unlock()
        }

        onAuthenticationEnded: {
            resetTimer.start()
        }
    }

    NonGraphicalFeedback {
        id: unlockFailedEvent
        event: "unlock_failed"
    }
}
