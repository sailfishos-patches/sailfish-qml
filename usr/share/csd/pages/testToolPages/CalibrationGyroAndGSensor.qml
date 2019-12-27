/*
 * Copyright (c) 2017 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0

SensorCalibrationPage {
    sensor: "accelerometer"

    //% "Accelerometer calibration"
    title: qsTrId("csd-he-accelerometer_calibration")
    description: {
        switch (type) {
        case "CALIBR_TYPE_ACCEL_1":
            //% "1. Put device on flat surface<br>2. Press Calibrate button"
            return qsTrId("csd-li-calibrate_accelerometer_1")
        case "":
            //% "Sensor calibration is not supported"
            return qsTrId("csd-li-calibrate_not_supported")
        default:
            //% "Calibration instructions not available"
            return qsTrId("csd-li-calibrate_no_instructions")
        }
    }
}
