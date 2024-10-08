/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import QOfono 0.2

Item {
    id: root

    property alias enteredPin: pinInput.enteredPin
    property alias modemPath: ofonoSimManager.modemPath
    property alias multiSimManager: pinInput.multiSimManager
    property alias showCancelButton: pinInput.showCancelButton
    property alias showBackgroundGradient: pinInput.showBackgroundGradient
    property alias emergency: pinInput.emergency

    property int _confirmedPinType
    property string _enteredPuk

    signal done(bool success)
    signal pinEntryCanceled()
    signal simPermanentlyLocked()

    width: parent.width
    height: parent.height

    function clear() {
        pinInput.clear()
    }

    function _finishedPinAction(error, errorString) {
        switch (error) {
        case OfonoSimManager.NotImplementedError:
        case OfonoSimManager.UnknownError:
            pinInput.retrying = false
            done(false)
            break
        case OfonoSimManager.InProgressError:
            break
        case OfonoSimManager.InvalidArgumentsError:
        case OfonoSimManager.InvalidFormatError:
        case OfonoSimManager.FailedError:
            pinInput.retrying = true
            pinInput.clear()
            break
        case OfonoSimManager.NoError:
            notification.body = ""
            if (_confirmedPinType === OfonoSimManager.ServiceProviderPersonalizationPin) {
                //: Indicates that the user entered the correct operator unlock code.
                //% "Unlock code correct"
                notification.body = qsTrId("settings_pin-la-notify_correct_unlock_code")
            } else if (ofonoSimManager.isPukType(_confirmedPinType)) {
                //: Indicates that the user entered the correct PUK (Pin Unblocking Key).
                //% "PUK code correct"
                notification.body = qsTrId("settings_pin-la-notify_correct_puk")
            } else {
                // no notification after the user entered the correct PIN
            }
            if (notification.body.length > 0) {
                notification.publish()
            }

            pinInput.retrying = false
            done(true)
            break
        }
    }

    OfonoSimManager {
        id: ofonoSimManager

        property bool trustPukCount: false

        onEnterPinComplete: _finishedPinAction(error, errorString)
        onResetPinComplete: _finishedPinAction(error, errorString)

        onPinRequiredChanged: {
            // reset the title text when changing from PIN -> PUK auth
            if (pinRequired === OfonoSimManager.SimPuk) {
                pinInput.retrying = false
            } else if (pinRequired === OfonoSimManager.NoPin) {
                trustPukCount = false
            }
        }

        onPinRetriesChanged: {
            for (var pinType in pinRetries) {
                if (pinType === OfonoSimManager.SimPuk.toString()) {
                    // ofono can send incorrect puk retry count so we cannot
                    // trust that the sim is blocked based on puk retry count
                    // alone. So let's check if we can trust the puk retry count.
                    if (pinRetries[pinType] > 0) {
                        trustPukCount = true
                    } else {
                        if (trustPukCount) {
                            console.log("JPO pintype: ", pinType, "OfonoSimManager type: ", OfonoSimManager.SimPuk.toString(), "retries: ", pinRetries[pinType])
                            root.simPermanentlyLocked()
                        } else {
                            trustPukCount = true
                        }
                    }
                }
            }
        }
    }

    SimPinInput {
        id: pinInput

        simManager: ofonoSimManager
        // Default to querying for PIN if no type is currently required
        requestedPinType: ofonoSimManager.pinRequired > 0 ? ofonoSimManager.pinRequired : OfonoSimManager.SimPin

        onPinConfirmed: {
            root._confirmedPinType = requestedPinType

            if (ofonoSimManager.isPukType(requestedPinType)) {
                if (root._enteredPuk === "") {
                    // PUK has been entered, now ask user for the new PIN so it can be reset
                    root._enteredPuk = enteredPin
                    requestAndConfirmNewPin()
                } else {
                    ofonoSimManager.resetPin(requestedPinType, root._enteredPuk, enteredPin)
                    root._enteredPuk = ""
                }
            } else {
                ofonoSimManager.enterPin(requestedPinType, enteredPin)
            }
        }

        onPinEntryCanceled: root.pinEntryCanceled()
    }

    Notification {
        id: notification

        isTransient: true
        urgency: Notification.Critical
        appIcon: "icon-system-resources"
    }
}
