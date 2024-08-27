/*
 * Copyright (c) 2018 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0

Column {
    property alias headerText: header.text
    property alias plainText: body.plainText

    width: parent.width

    MessageInfoLabel {
        id: header
        font.pixelSize: Theme.fontSizeMedium
        header: true
    }

    LinkedText {
        id: body
        x: Theme.horizontalPageMargin
        width: parent.width - 2*x
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
    }
}
