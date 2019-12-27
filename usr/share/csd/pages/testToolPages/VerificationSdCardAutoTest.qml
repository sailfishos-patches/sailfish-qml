/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import ".."

AutoTest {
    id: test

    function run() {
        if (sdcardtest.status == SdCardTest.Mounted) {
            testIO()
        } else if (sdcardtest.mountFailed) {
            setTestResult(false)
        } else {
            // No card, or waiting for it to mount.
        }
    }

    function testIO() {
        var sdCardStatus = sdcardtest.sdCardIOTest()
        switch (sdCardStatus) {
        case 0:
            // This is OK - there may not be an SD card installed.
            // Leave result as is.
            break
        case 1: // Writing data to SD card failed.
        case 2: // Reading data from SD card failed.
            setTestResult(false)
            break
        case 3:
            setTestResult(true)
            break
        }
    }

    SdCardTest {
        id: sdcardtest

        onStatusChanged: {
            if (status == SdCardTest.Mounted) {
                testIO()
            }
        }

        onMountFailedChanged: {
            if (mountFailed) {
                setTestResult(false)
            }
        }
    }
}
