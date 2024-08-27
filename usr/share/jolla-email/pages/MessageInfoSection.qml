/*
 * Copyright (c) 2018 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    property alias headerText: header.text
    property alias bodyText: body.text

    width: parent.width
    MessageInfoLabel {
        id: header
        font.pixelSize: Theme.fontSizeMedium
        header: true
    }

    MessageInfoLabel {
        id: body
    }
}
