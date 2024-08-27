/*
 * Copyright (c) 2016 - 2023 Jolla Ltd.
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

    // Actual sampling rate might vary from one device to another
    // Normalize ui visuals by doing timer based subsampling
    readonly property int subsampleRate: 2
    readonly property int sampleRate: subsampleRate * 2 + 1
    readonly property int samplesNeeded: 32
    property int samplesAcquired
    readonly property int secondsRemaining: (samplesNeeded - samplesAcquired + subsampleRate - 1) / subsampleRate

    // The latest sensor values seen
    property real rawX
    property real rawY
    property real rawZ

    // The latest sensor values picked for use
    property real curX
    property real curY
    property real curZ

    // Average of the first samplesNeeded picked values
    property real avgX
    property real avgY
    property real avgZ

    // Pass/Fail limits from config
    readonly property real gyroMin: CsdHwSettings.gyroMin
    readonly property real gyroMax: CsdHwSettings.gyroMax

    function start() {
        if (!running) {
            testPassed = false
            done = false
            running = true
            subsampleTimer.start()
        }
    }

    function _subsample() {
        curX = rawX
        curY = rawY
        curZ = rawZ
        _accumulate()
    }

    function _accumulate() {
        if (samplesAcquired < samplesNeeded) {
            avgX += curX
            avgY += curY
            avgZ += curZ
            if (++samplesAcquired == samplesNeeded) {
                _average()
            }
        }
    }

    function _average() {
        avgX /= samplesAcquired
        avgY /= samplesAcquired
        avgZ /= samplesAcquired

        testPassed = (avgX || avgY || avgZ)
                     && gyroMin < avgX && avgX < gyroMax
                     && gyroMin < avgY && avgY < gyroMax
                     && gyroMin < avgZ && avgZ < gyroMax
        done = true
        running = false
    }

    Gyroscope {
        dataRate: sampleRate
        active: true
        onReadingChanged: {
            if (reading) {
                rawX = reading.x
                rawY = reading.y
                rawZ = reading.z
            }
        }
    }

    Timer {
        id: subsampleTimer
        interval: 1000 / subsampleRate
        repeat: true
        onTriggered: _subsample()
    }
}
