/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import QtFeedback 5.0
import org.nemomobile.systemsettings 1.0

Item {
    property alias running: hapticsEffect.running
    property var _vibraMode

    function stop() {
        vibratorTimer.stop()
        hapticsEffect.stop()
    }

    ProfileControl { id: profileControl }

    HapticsEffect {
        id: hapticsEffect
        intensity: 0.9
        duration: 36000
    }

    // Repeat vibrate in case of vibrator is not working
    // Workaround for bug below
    // bool QFeedbackFFMemless::uploadEffect(ff_effect*) Unable to upload effect
    Timer {
        id: vibratorTimer
        repeat: true
        interval: 1000
        onTriggered: {
            hapticsEffect.stop()
            hapticsEffect.start()
        }
    }

    Component.onCompleted: {
        _vibraMode = profileControl.vibraMode
        profileControl.vibraMode = ProfileControl.VibraAlways
        vibratorTimer.start()
    }
    Component.onDestruction: {
        vibratorTimer.stop()
        hapticsEffect.stop()
        profileControl.vibraMode = _vibraMode
    }
}
