/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtSensors 5.0
import Csd 1.0
import ".."

Item {
    property bool running
    property bool done
    property bool testPassed

    property double gsensorX
    property double gsensorY
    property double gsensorZ
    property double averageGsensorX
    property double averageGsensorY
    property double averageGsensorZ
    property int sleeptime: 500
    property int times: 5

    property double minX: CsdHwSettings.gSensorMinX
    property double maxX: CsdHwSettings.gSensorMaxX
    property double minY: CsdHwSettings.gSensorMinY
    property double maxY: CsdHwSettings.gSensorMaxY
    property double minZ: CsdHwSettings.gSensorMinZ
    property double maxZ: CsdHwSettings.gSensorMaxZ

    function start() {
        testPassed = false
        done = false
        running = true

        timer.start()
    }

    function _getValues() {
        averageGsensorX = averageGsensorX + gsensorX
        averageGsensorY = averageGsensorY + gsensorY
        averageGsensorZ = averageGsensorZ + gsensorZ
    }

    function _checkRange() {
        averageGsensorX = averageGsensorX/5
        averageGsensorY = averageGsensorY/5
        averageGsensorZ = averageGsensorZ/5

        testPassed = averageGsensorX > minX && averageGsensorX < maxX
                      && averageGsensorY > minY && averageGsensorY < maxY
                      && averageGsensorZ > minZ && averageGsensorZ < maxZ
        done = true
        running = false
    }

    Accelerometer {
        id: accelerometer
        dataRate: 5000
        active: true
        onReadingChanged: {
            if (reading) {
                gsensorX = reading.x
                gsensorY = reading.y
                gsensorZ = reading.z
            }
        }
    }

    Timer {
        id: timer
        interval: sleeptime
        repeat: true
        onTriggered: {
            if (times > 0) {
                times--
                _getValues()
            } else {
                timer.stop()
                _checkRange()
            }
        }
    }
}
