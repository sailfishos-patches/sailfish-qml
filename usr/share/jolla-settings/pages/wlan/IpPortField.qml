import QtQuick 2.0
import Sailfish.Silica 1.0

TextField {
    property var regExp: new RegExp(/^[0-9]+$/)
    property bool validInput: {
        var number = Number(text)
        return regExp.test(text) && number !== NaN && number >= 0 && number <= 65535
    }
    property bool weakValid: validInput || text == ""

    onWeakValidChanged: errorHighlight = !weakValid
    onActiveFocusChanged: if (!activeFocus && !validInput) errorHighlight = true
    onValidInputChanged: if (validInput) errorHighlight = false

    width: parent.width
    inputMethodHints: Qt.ImhDigitsOnly

    //% "E.g. 8080"
    placeholderText: qsTrId("settings_network-la-proxy_port_example")

    //% "Port number"
    label: qsTrId("settings_network-la-proxy_port_number")
    hideLabelOnEmptyField: false
}
