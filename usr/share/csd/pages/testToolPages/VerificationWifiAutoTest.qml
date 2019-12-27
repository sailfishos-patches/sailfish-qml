/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

AutoTest {
    id: test

    function run() {
        wifiTechModel.initTestCase()
        wifiTechModel._checkCount()
    }

    VerificationTechnologyModel {
        id: wifiTechModel

        function _checkCount() {
            if (count > 0) {
                done(true)
            }
        }

        name: "wifi"

        onFinished: test.setTestResult(success)

        onScanRequestFinished: {
            if (page.state == "scanning" && count == 0) {
                done(false)
            }
        }

        onCountChanged: {
            _checkCount()
        }
    }
}
