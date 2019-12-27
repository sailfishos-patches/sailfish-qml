/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import Csd 1.0

BackgroundItem {
    readonly property bool testStatusVisible: actualResult === FactoryUtils.Pass || actualResult === FactoryUtils.Fail
    readonly property bool untested: actualResult === FactoryUtils.Untest
    property alias testStatusColor: testStatus.color

    readonly property string actualResult: {
        if (result == FactoryUtils.Untest)
            return FactoryUtils.Untest
        else if (result == 1)
            return FactoryUtils.Pass
        else
            return FactoryUtils.Fail
    }

    readonly property string testStatus: {
        if (actualResult === FactoryUtils.Untest) {
            //% "Not tested"
            return qsTrId("csd-la-not_tested")
        } else if (actualResult === FactoryUtils.Pass) {
            //% "Pass"
            return qsTrId("csd-la-pass")
        } else {
            //% "Fail"
            return qsTrId("csd-la-fail")
        }
    }

    Rectangle {
        id: testStatus
        anchors.fill: parent
        visible: testStatusVisible
        color: result == 1 ? "green" : "red"
    }
}
