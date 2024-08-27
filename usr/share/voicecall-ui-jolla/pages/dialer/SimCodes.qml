import QtQuick 2.0
import Sailfish.Silica 1.0
import QOfono 0.2

Item {
    id: root
    property alias modemPath: simManager.modemPath
    property alias cardIdentifier: simManager.cardIdentifier
    property alias present: simManager.present
    property string changingPin
    property int changingPinType

    function processCode(code) {
        if (code[code.length-1] !== '#') {
            // should never happen
            console.log("SIM code missing # terminator")
            return
        }

        var message
        code = code.substring(0, code.length-1)
        if (code.indexOf("**04*") === 0) {
            changingPin = "PIN"
            message = _changePin(OfonoSimManager.SimPin, code.substring(5))
        } else if (code.indexOf("**042*") === 0) {
            changingPin = "PIN2"
            message = _changePin(OfonoSimManager.SimPin2, code.substring(6))
        } else if (code.indexOf("**05*") === 0) {
            changingPin = "PIN"
            message = _resetPin(OfonoSimManager.SimPuk, code.substring(5))
        } else if (code.indexOf("**052*") === 0) {
            changingPin = "PIN2"
            message = _resetPin(OfonoSimManager.SimPuk2, code.substring(6))
        } else {
            // should never happen
            console.log("Unsupported SIM code " + code)
            return
        }

        var page = showServicePage(message)
        if (message === "") {
            if (code.indexOf("**05") === 0) {
                //: Resetting PIN (or PIN2)
                //% "Resetting %1"
                page.message = qsTrId("voicecall-la-resetting_pin").arg(changingPin)
            } else {
                //: Changing PIN (or PIN2)
                //% "Changing %1"
                page.message = qsTrId("voicecall-la-changing_pin").arg(changingPin)
            }
            page.busy = true
        }
    }

    function _changePin(type, pins) {
        var pinArray = pins.split("*")
        if (pinArray.length !== 3) {
            //% "Invalid SIM command"
            return qsTrId("voicecall-la-invalid_sim_command")
        }

        var pinExp=/\d{4,8}$/
        for (var i = 0; i < 3; i++) {
            if (pinExp.test(pinArray[i]) === false) {
                //% "Invalid PIN format"
                return qsTrId("voicecall-la-invalid_pin_format")
            }
        }

        if (pinArray[1] !== pinArray[2]) {
            //% "New PIN codes do not match"
            return qsTrId("voicecall-la-pins_do_not_match")
        }

        if (pinArray[0] === pinArray[1]) {
            //% "The new PIN cannot be the same as the current PIN"
            return qsTrId("voicecall-la-new_pin_same_as_old")
        }

        changingPinType = type
        simManager.changePin(type, pinArray[0], pinArray[1])

        return ""
    }

    function _resetPin(type, pins) {
        var pinArray = pins.split("*")
        if (pinArray.length !== 3) {
            //% "Invalid SIM command"
            return qsTrId("voicecall-la-invalid_sim_command")
        }

        var pukExp=/\d{8,16}$/
        if (pukExp.test(pinArray[0]) === false) {
            //% "Invalid PUK format"
            return qsTrId("voicecall-la-invalid_puk_format")
        }

        var pinExp=/\d{4,8}$/
        for (var i = 1; i < 3; i++) {
            if (pinExp.test(pinArray[i]) === false) {
                //% "Invalid PIN format"
                return qsTrId("voicecall-la-invalid_pin_format")
            }
        }

        if (pinArray[1] !== pinArray[2]) {
            //% "New PIN codes do not match"
            return qsTrId("voicecall-la-pins_do_not_match")
        }

        changingPinType = type
        simManager.resetPin(type, pinArray[0], pinArray[1])

        return ""
    }

    function showServicePage(message, showRetries) {
        var props = {}
        if (showRetries !== undefined && showRetries === true) {
            props = Qt.binding(function() {
                var properties = {}
                var retries = simManager.pinRetries[changingPinType]
                if (!isNaN(retries)) {
                    //: Shows remaining PIN entry attempts in the form "Attempts remaining: 2"
                    //% "Attempts remaining"
                    properties[qsTrId("voicecall-la-pin_retries_remaining")] = retries
                }
                return properties
            })
        }

        //% "Change %1"
        return supplementaryServices.showServicePage({ "message": message,
                                                  "title": qsTrId("voicecall-he-change_pin").arg(changingPin),
                                                  "properties": props })

    }

    OfonoSimManager {
        id: simManager
        function respondToPinChange(error, errorString){
            var message
            switch (error) {
            case OfonoSimManager.NotImplementedError:
            case OfonoSimManager.UnknownError:
                //: Indicates that the entered PIN was not accepted due to a SIM error.
                //% "PIN entry error"
                message = qsTrId("voicecall-la-notify_general_error")
                break
            case OfonoSimManager.InvalidArgumentsError:
            case OfonoSimManager.InvalidFormatError:
            case OfonoSimManager.FailedError:
                //: Indicates that the user entered an incorrect PIN.
                //% "Incorrect PIN code"
                message = qsTrId("voicecall-la-notify_incorrect_pin")
                break
            case OfonoSimManager.NoError:
                //: PIN code changed successfully
                //% "%1 code successfully changed"
                message = qsTrId("voicecall-la-pin_code_changed").arg(changingPin)
                break
            default:
                message = errorString
                break
            }
            showServicePage(message, error !== OfonoSimManager.NoError)
        }

        onChangePinComplete: respondToPinChange(error, errorString)
        onResetPinComplete: respondToPinChange(error, errorString)
    }
}
