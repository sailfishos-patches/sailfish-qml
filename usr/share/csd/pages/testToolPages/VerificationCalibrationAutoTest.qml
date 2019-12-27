/*
 * Copyright (c) 2018 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import ".."

AutoTest {
    id: test

    function isCalibrated() {
        return calibrationTest.isCalibrationFlagOk() && calibrationTest.isCalibrationStringOk()
    }

    function run() {
        setTestResult(isCalibrated())
    }

    CalibrationTest {
        id: calibrationTest
    }
}

