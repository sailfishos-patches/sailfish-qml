/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    property alias title: titleLabel.text
    property alias text: descriptionLabel.text

    x: Theme.paddingLarge
    width: parent.width-(2*Theme.paddingLarge)
    spacing: Theme.paddingLarge

    Label {
        id: titleLabel
        width: parent.width
        font.pixelSize: Theme.fontSizeExtraLarge
        font.family: Theme.fontFamilyHeading
        //% "Test procedure"
        text: qsTrId("csd-la-test_procedure")
        wrapMode: Text.Wrap
        visible: text.length > 0
    }

    Label {
        id: descriptionLabel
        width: parent.width
        wrapMode: Text.Wrap
        textFormat: Text.AutoText
    }
}
