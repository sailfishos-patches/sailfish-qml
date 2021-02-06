import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0

NetworkField {

    // Input mask "0-255.0-255.0-255.0-255"
    property var inputRegExp: new RegExp(/^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/)
    property bool emptyInputOk: false

    regExp: (emptyInputOk && length === 0) ? null : inputRegExp

    //% "Valid IPv4 address is required"
    description: errorHighlight ? qsTrId("settings_network_la-ipv4_address_field_error") : ""

    // During typing only validate characters
    property var weakRegExp: new RegExp(/^[0-9\.]*$/)
    onTextChanged: errorHighlight = (length > 0 && !weakRegExp.test(text))

    // TODO: use Qt.ImhFormattedNumbersOnly, but so that decimal point is always "."
    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhPreferNumbers | Qt.ImhLatinOnly
}
