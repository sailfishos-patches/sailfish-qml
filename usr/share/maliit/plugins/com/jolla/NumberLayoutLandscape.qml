// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0 as Silica
import com.jolla.keyboard 1.0

KeyboardLayout {
    id: main

    property real keyWidth: width / 10

    width: geometry.keyboardWidthLandscape
    height: 2 * geometry.keyHeightPortrait

    Row {
        NumberKey {
            caption: "1"
            width: main.keyWidth
        }
        NumberKey {
            caption: "2"
            width: main.keyWidth
        }
        NumberKey {
            caption: "3"
            width: main.keyWidth
        }
        NumberKey {
            caption: "4"
            width: main.keyWidth
        }
        NumberKey {
            caption: "5"
            width: main.keyWidth
        }
        NumberKey {
            caption: "6"
            width: main.keyWidth
        }
        NumberKey {
            caption: "7"
            width: main.keyWidth
        }
        NumberKey {
            caption: "8"
            width: main.keyWidth
        }
        NumberKey {
            caption: "9"
            width: main.keyWidth
        }
        NumberKey {
            caption: "0"
            width: main.keyWidth
            separator: SeparatorState.HiddenSeparator
        }
    }

    Row {
        x: 4 * main.keyWidth

        NumberKey {
            width: main.keyWidth
            enabled: Silica.Clipboard.hasText
            opacity: enabled ? (pressed ? 0.6 : 1.0)
                             : 0.3
            key: Qt.Key_Paste

            Image {
                anchors.centerIn: parent
                source: "image://theme/icon-m-clipboard?"
                        + (parent.pressed ? Silica.Theme.highlightColor : Silica.Theme.primaryColor)
            }
        }
        NumberKey {
            width: main.keyWidth
            key: Qt.Key_Multi_key
            caption: "+/-"
            text: "+-"
        }
        NumberKey {
            width: main.keyWidth
            caption: Qt.locale().decimalPoint
            separator: SeparatorState.HiddenSeparator
        }
        BackspaceKey {
            width: main.keyWidth
            height: geometry.keyHeightPortrait
        }
        EnterKey {
            width: 2 * main.keyWidth
            height: geometry.keyHeightPortrait
        }
    }
}
