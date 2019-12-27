/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import org.nemomobile.dbus 2.0
import ".."

CsdTestPage {
    id: page
    property QtObject _ngfEffect

    property int hallChangeCount

    function resetOriginalValues() {
        mce.typedCall("set_config", [ { type: "s", value: "/system/osso/dsm/locks/lid_sensor_enabled"}, {type: "v", value: mce.originalValue} ])
    }

    function stopTest(result) {
        setTestResult(result)
        testCompleted(true)
    }

    Component.onDestruction: {
        resetOriginalValues()
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        CsdPageHeader {
            //% "Hall sensor"
            title: qsTrId("csd-he-hall_sensor")
        }
        DescriptionItem {
            id: stepText
            //% "1. Make sure cover or magnet is not connected.<br>2. Please close the cover cover or attach magnet for a second.<br> 3. Open cover and see the test result."
            text: qsTrId("csd-la-verification_hall_detect_description")
        }
    }

    DBusInterface {
        id: mce

        property bool originalValue

        service: "com.nokia.mce"
        iface: "com.nokia.mce.request"
        path: "/com/nokia/mce/request"
        bus: DBus.SystemBus
    }

    Component.onCompleted: {
        hallDetect.openFile()
        mce.typedCall("get_config", [ {type: "s", value:"/system/osso/dsm/locks/lid_sensor_enabled"}], function(r) {
            mce.originalValue = r
        })
        mce.typedCall("set_config", [ { type: "s", value: "/system/osso/dsm/locks/lid_sensor_enabled"}, {type: "v", value: false} ])
        _ngfEffect = Qt.createQmlObject("import org.nemomobile.ngf 1.0; NonGraphicalFeedback { event: 'unlock_device' }",
                                        page, 'NonGraphicalFeedback');
    }

    Label {
        id: resultPass
        anchors.centerIn: parent
        color: "green"
        visible: hallChangeCount >= 2
        wrapMode: Text.WordWrap
        width: parent.width-(2*Theme.paddingLarge)
        font.pixelSize: Theme.fontSizeLarge
        //% "Hall detection test passed!"
        text: qsTrId("csd-la-hall_detection_test_passed")
    }

    HallDetect {
        id: hallDetect
        onHallChanged: {
            hallChangeCount += 1
            effect.running = true
        }
    }

    // After finding hall magnet automatically finalize the test.
    Timer {
        interval: 4000
        running: resultPass.visible
        repeat: false
        onTriggered: stopTest(true)
    }

    Timer {
        id: effect
        interval: 10
        running: false
        repeat: false
        onTriggered: if (_ngfEffect) _ngfEffect.play()
    }

    FailBottomButton {
        visible: !resultPass.visible
        onClicked: stopTest(false)
    }
}
