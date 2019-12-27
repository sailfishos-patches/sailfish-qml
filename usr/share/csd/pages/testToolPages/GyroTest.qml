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
    id: root

    property real sensorX
    property real sensorY
    property real sensorZ

    property real valueX
    property real valueY
    property real valueZ

    property bool running
    property bool done
    property bool testPassed
    property int secondsRemaining: timer2.count == 0 ? 0 : Math.round(16 - (timer2.count / 2))

    function start() {
        if (running) {
            return
        }
        testPassed = false
        done = false
        running = true

        timer2.start()
        timer1.start()
    }

    function _retrieveGyroData() {
        if (timer2.count < 32) {
            sensor.updateGyroSensor()
            timer2.count = timer2.count + 1
        }

        var sensorResult = sensor.getResult
        if (!timer1.running) {
            root.testPassed = sensorResult
            done = true
            running = false
        }

        sensorX = sensor.getXResult
        sensorY = sensor.getYResult
        sensorZ = sensor.getZResult
    }

    Timer {
        id: timer1
        interval: 16500
        onTriggered: {
            timer2.stop()
            root._retrieveGyroData()
        }
    }

    Timer {
        id: timer2
        property int count
        interval: 500
        repeat: true
        triggeredOnStart: true
        onTriggered: root._retrieveGyroData()
    }

    GyroSensor {
        id: sensor
    }

    Gyroscope {
        active: true
        onReadingChanged: {
            if (reading) {
                valueX = reading.x
                valueY = reading.y
                valueZ = reading.z
            }
        }
    }
}
