/*
 * Copyright (c) 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0

NetworkField {
    // IPv4, IPv6 or empty input mask
    property var ipRegExp: new RegExp(/^(([a-f0-9]{0,4}:){0,7}([a-f0-9]{0,4})(:|^|$)((((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))?))?$/)
    property bool emptyInputOk

    _suppressPressAndHoldOnText: true
    focusOutBehavior: FocusBehavior.KeepFocus
    focusOnClick: false
    onClicked: forceActiveFocus()

    regExp: (emptyInputOk && length === 0) ? null : ipRegExp

    //% "Valid IP address is required"
    description: errorHighlight ? qsTrId("settings_network_la-ip_address_field_error") : ""

    function updateErrorHighlight() {
        errorHighlight = (!emptyInputOk && length === 0) || !ipRegExp.test(text)
    }

    onTextChanged: updateErrorHighlight()

    // TODO: use Qt.ImhFormattedNumbersOnly, but so that decimal point is always "."
    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhPreferNumbers | Qt.ImhLatinOnly
}
