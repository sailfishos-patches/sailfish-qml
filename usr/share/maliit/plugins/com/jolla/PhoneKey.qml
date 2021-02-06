// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.keyboard 1.0

KeyBase {
    id: aCharKey

    property alias secondaryLabel: secondaryLabel.text
    property bool separator: true
    property bool landscape

    keyType: KeyType.CharacterKey
    text: mainLabel.text
    showPopper: false

    Row {
        x: parent.width / (parent.landscape ? 5 : 3)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.paddingSmall

        Label {
            id: mainLabel
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
            text: caption
        }
        Label {
            id: secondaryLabel
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }

    KeySeparator {
        visible: separator
    }

    Rectangle {
        anchors.fill: parent
        z: -1
        color: aCharKey.palette.highlightBackgroundColor
        opacity: 0.5
        visible: pressed
    }
}

