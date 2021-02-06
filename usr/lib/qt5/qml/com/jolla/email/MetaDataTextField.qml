/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

CompressibleItem {
    id: root
    property alias placeholderText: textField.placeholderText
    property alias text: textField.text

    signal enterKeyClicked

    function forceActiveFocus() {
        textField.forceActiveFocus()
    }

    compressible: textField.text.length === 0

    TextField {
        id: textField
        visible: !root.compressed
        anchors.bottom: parent.bottom
        horizontalAlignment: Text.AlignLeft

        EnterKey.enabled: text.length > 0
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: root.enterKeyClicked()
    }
}
