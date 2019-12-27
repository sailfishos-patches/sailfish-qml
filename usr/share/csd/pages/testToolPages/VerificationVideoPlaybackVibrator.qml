/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

VerificationVideoPlayback {
    id: page

    onStatusChanged: {
        if (page.status === PageStatus.Deactivating) {
            testVibrator.stop()
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: page.status === PageStatus.Active
        onTriggered: testVibrator.running = !testVibrator.running
    }

    Vibrator {
        id: testVibrator
    }
}
