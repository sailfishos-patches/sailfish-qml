/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

QtObject {
    signal testFinished(bool passFail)

    function setTestResult(passFail) {
        testFinished(passFail)
    }
    default property QtObject __props: []
}
