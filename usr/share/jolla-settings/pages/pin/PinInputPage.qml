import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import com.jolla.settings.system 1.0
import MeeGo.QOfono 0.2

Page {
    id: pinInputPage

    // 'lock', 'unlock' or 'change'
    property string pinAction
    property alias ofonoSimManager: pinInput.simManager

    property string _oldPin

    function retry() {
        pinInput.retrying = true
        pinInput.clear()
    }

    backNavigation: false

    SimPinInput {
        id: pinInput

        SimManager { id: sailfishSimManager }

        multiSimManager: sailfishSimManager

        requestedPinType: OfonoSimManager.SimPin
        showCancelButton: true

        onPinConfirmed: {
            if (pinInputPage.pinAction == "lock") {
                ofonoSimManager.lockPin(OfonoSimManager.SimPin, enteredPin)
            } else if (pinInputPage.pinAction == "unlock") {
                ofonoSimManager.unlockPin(OfonoSimManager.SimPin, enteredPin)
            } else if (pinInputPage.pinAction == "change") {
                if (pinInputPage._oldPin === "") {
                    pinInputPage._oldPin = enteredPin
                    requestAndConfirmNewPin(enteredPin)
                } else {
                    ofonoSimManager.changePin(OfonoSimManager.SimPin, pinInputPage._oldPin, enteredPin)
                    pinInputPage._oldPin = ""
                }
            }
        }

        onPinEntryCanceled: {
            pageStack.pop()
        }
    }
}
