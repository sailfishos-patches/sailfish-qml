/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0
import Nemo.Notifications 1.0
import QOfono 0.2

Column {
    id: root

    property alias modemPath: ofonoSimManager.modemPath
    property int multiModemIndex: -1
    property string shortSimDescription
    property alias simManager: ofonoSimManager

    property Item _pinInputPage
    property bool _pinQueryOk
    property bool _forcePinLocked

    width: parent.width

    function _finishedPinAction(error, errorString) {
        if (_pinInputPage === null) {
            return
        }
        _forcePinLocked = false
        switch (error) {
        case OfonoSimManager.NotImplementedError:
        case OfonoSimManager.UnknownError:
            //: Indicates that the entered PIN was not accepted due to a SIM error.
            //% "PIN entry error"
            notification.body = qsTrId("settings_pin-la-notify_general_error")
            notification.publish()
            pageStack.pop()
            _pinInputPage = null
            break
        case OfonoSimManager.InProgressError:
            break
        case OfonoSimManager.InvalidArgumentsError:
        case OfonoSimManager.InvalidFormatError:
        case OfonoSimManager.FailedError:
            if (_pinInputPage.pinAction === "change") {
                //: Indicates that the user entered an incorrect PIN.
                //% "Incorrect PIN code"
                notification.body = qsTrId("settings_pin-la-notify_incorrect_pin")
                notification.publish()
            }
            _pinInputPage.retry()
            break
        case OfonoSimManager.NoError:
            if (_pinInputPage.pinAction === "change") {
                //: Indicates that the PIN was successfully changed.
                //% "PIN code changed"
                notification.body = qsTrId("settings_pin-la-notify_pin_changed")
                notification.publish()
            }
            pageStack.pop()
            _pinInputPage = null
            break
        }
    }

    OfonoSimManager {
        id: ofonoSimManager

        onLockPinComplete: root._finishedPinAction(error, errorString)
        onUnlockPinComplete: root._finishedPinAction(error, errorString)
        onChangePinComplete: root._finishedPinAction(error, errorString)

        onPinRequiredChanged: {
            if (pinRequired === OfonoSimManager.NoPin) {
                root._pinQueryOk = false
            } else if (pinRequired === OfonoSimManager.SimPuk
                    && root._pinInputPage !== null && pageStack.currentPage === root._pinInputPage) {
                // User has entered incorrect PIN too many times and SIM is now locked. The
                // system PIN input UI will open automatically, so close the pin input page after
                // the system UI is displayed.
                pageStack.pop()
                _pinInputPage = null

                // As SIM is now locked with PUK, it is now automatically set to PIN locked, but
                // ofono may not notify of this change. See JB#11115
                _forcePinLocked = true
            }
        }
    }

    TextSwitch {
        id: pinEnabledSwitch
        x: Theme.horizontalPageMargin
        automaticCheck: false
        checked: root._forcePinLocked || ofonoSimManager.lockedPins.indexOf(OfonoSimManager.SimPin) >= 0

        //: Enable/disable SIM card PIN lock
        //% "Require PIN code"
        text: qsTrId("settings_pin-bt-lock_sim")

        onClicked: {
            var pinAction = checked ? "unlock" : "lock"

            var obj = pageStack.animatorPush(Qt.resolvedUrl("PinInputPage.qml"), {"pinAction": pinAction, "ofonoSimManager": ofonoSimManager})
            obj.pageCompleted.connect(function(page) {
                root._pinInputPage = page
            })
        }
    }

    Button {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: pinEnabledSwitch.checked
        preferredWidth: Theme.buttonWidthLarge

        //: Change the current SIM PIN code
        //% "Change PIN code"
        text: qsTrId("settings_pin-bt-change_pin")

        onClicked: {
            var obj = pageStack.animatorPush("PinInputPage.qml", {"pinAction": "change", "ofonoSimManager": ofonoSimManager})
            obj.pageCompleted.connect(function(page) {
                root._pinInputPage = page
            })
        }
    }

    Notification {
        id: notification

        isTransient: true
        urgency: Notification.Critical
        appIcon: "icon-system-resources"
    }
}
