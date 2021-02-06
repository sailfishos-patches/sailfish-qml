import QtQuick 2.0
import Sailfish.Silica 1.0

TextField {
    property var regExp: new RegExp(/^[0-9]+$/)
    acceptableInput: {
        var number = Number(text)
        return regExp.test(text) && number !== NaN && number >= 0 && number <= 65535
    }
    property bool weakValid: acceptableInput || text == ""

    onWeakValidChanged: errorHighlight = !weakValid
    onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput
    onAcceptableInputChanged: if (acceptableInput) errorHighlight = false

    width: parent.width
    inputMethodHints: Qt.ImhDigitsOnly

    //% "E.g. 8080"
    placeholderText: qsTrId("settings_network-la-proxy_port_example")

    //% "Port number"
    label: qsTrId("settings_network-la-proxy_port_number")

    //% "Port number must be a value between 0 and 65535"
    description: errorHighlight ? qsTrId("settings_network_la-proxy_port_number_error") : ""

    hideLabelOnEmptyField: false
}
