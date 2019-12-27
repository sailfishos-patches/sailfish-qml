/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Sailfish.Media 1.0
import Csd 1.0
import org.nemomobile.policy 1.0
import org.nemomobile.dbus 2.0
import ".."

CsdTestPage {
    id: page

    property int keysPressed
    property int keysReleased

    property bool haveButtonBacklight: Features.supported("ButtonBacklight")
    property bool pass: CsdHwSettings.keys.length == keysPressed && CsdHwSettings.keys.length == keysReleased

    onPassChanged: {
        if (pass) {
            setTestResult(true)
            testCompleted(true)
        }
    }

    // Stop home key from backgrounding the test app
    Private.WindowGestureOverride {
        active: true
    }

    Column {
        width: parent.width

        CsdPageHeader {
            //% "Key"
            title: qsTrId("csd-he-key")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width -2*x
            wrapMode: Text.Wrap
            //% "Please click all the keys listed below"
            text: qsTrId("csd-la-please_click_all_keys")
            font.pixelSize: Theme.fontSizeLarge
        }
        Item {
            width: parent.width
            height: Theme.paddingLarge
        }

        Repeater {
            model: CsdHwSettings.keys

            TextSwitch {
                property bool pressHandled
                property bool releaseHandled
                property string name: CsdHwSettings.keyName(modelData)

                automaticCheck: false
                highlighted: true
                text: name

                MediaKey {
                    enabled: key == Qt.Key_VolumeUp || key == Qt.Key_VolumeDown ? volumeKeysResource.acquired : true
                    key: modelData
                    onPressed: {
                        console.log(name + "key pressed")
                        if (!pressHandled) {
                            keysPressed = keysPressed + 1
                            pressHandled = true
                        }
                    }
                    onReleased: {
                        console.log(name + "key released")
                        if (!releaseHandled) {
                            keysReleased = keysReleased + 1
                            releaseHandled = true
                        }
                        checked = true
                    }
                }
            }
        }
    }

    FailBottomButton {
        onClicked: {
            setTestResult(false)
            testCompleted(true)
        }
    }

    Permissions {
        enabled: true
        autoRelease: true
        applicationClass: "camera"

        Resource {
            id: volumeKeysResource
            type: Resource.ScaleButton
            optional: true
        }
    }

    DBusInterface {
        id: mceControl
        bus: DBus.SystemBus
        service: "com.nokia.mce"
        path: "/com/nokia/mce/request"
        iface: "com.nokia.mce.request"
    }

    Component.onCompleted: {
        if (haveButtonBacklight) {
            mceControl.call("req_button_backlight_change", true)
        }
    }

    Component.onDestruction: {
        if (haveButtonBacklight) {
            mceControl.call("req_button_backlight_change", false)
        }
    }
}
