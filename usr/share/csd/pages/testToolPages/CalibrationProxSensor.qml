/*
 * Copyright (c) 2017 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0

SensorCalibrationPage {
    sensor: "proximity"

    //% "Proximity calibration"
    title: qsTrId("csd-he-proximity_calibration")
    description: {
        switch (type) {
        case "CALIBR_TYPE_PROXIMITY_1":
            //% "1. Have nothing over the sensor<br>2. Press Calibrate button"
            return qsTrId("csd-li-calibrate_proximity_1")
        case "":
            //% "Sensor calibration is not supported"
            return qsTrId("csd-li-calibrate_not_supported")
        default:
            //% "Calibration instructions not available"
            return qsTrId("csd-li-calibrate_no_instructions")
        }
    }
}
