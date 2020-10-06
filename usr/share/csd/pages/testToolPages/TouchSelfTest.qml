/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    CsdPageHeader {
        id: title
        //% "Touch IC self test"
        title: qsTrId("csd-he-touch_ic_self_test")
    }

    Component.onCompleted: {
        touchHandler.start()
    }

    Column {
        id: headerColumn
        width: parent.width - Theme.paddingLarge * 2
        spacing: Theme.paddingLarge
        anchors.top: title.bottom

        Label {
            x: Theme.paddingLarge
            //% "Automated Touch IC test ongoing. Please wait a moment to give test some time to complete."
            text: qsTrId("csd-la-automated_touch_ic_test_ongoing")
            width: parent.width-(2*Theme.paddingLarge)
            wrapMode: Text.Wrap
        }
    }

    Row {
        id: statusRow
        anchors.top: headerColumn.bottom
        anchors.topMargin: Theme.paddingLarge + 50
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.paddingMedium

        Label {
            id: statusLabel
            //% "Test status:"
            text: qsTrId("csd-la-test_status")
        }

        Label {
            id: status
            //% "Testing..."
            text: qsTrId("csd-la-testing")
        }
    }

    Touch {
        id: touchHandler

        onResultChanged: {
            status.color = result ? "green":"red"
            status.text = result ? 
                //% "Pass"
                qsTrId("csd-la-pass") :
                //% "Fail"
                qsTrId("csd-la-fail")
            setTestResult(result)
            testCompleted(false)
        }
    }
}
