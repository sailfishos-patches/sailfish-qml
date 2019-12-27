// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0 as Silica
import com.jolla.keyboard 1.0

KeyboardLayout {
    id: main

    property real keyWidth: width / 4

    portraitMode: true
    height: 4 * geometry.keyHeightPortrait

    Row {
        NumberKey {
            width: main.keyWidth
            caption: "1"
        }
        NumberKey {
            width: main.keyWidth
            caption: "2"
        }
        NumberKey {
            width: main.keyWidth
            caption: "3"
        }
        NumberKey {
            width: main.keyWidth
            enabled: Silica.Clipboard.hasText
            separator: SeparatorState.HiddenSeparator
            opacity: enabled ? (pressed ? 0.6 : 1.0)
                             : 0.3
            key: Qt.Key_Paste

            Image {
                anchors.centerIn: parent
                source: "image://theme/icon-m-clipboard?"
                        + (parent.pressed ? Silica.Theme.highlightColor : Silica.Theme.primaryColor)
            }
        }
    }

    Row {
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
            width: main.keyWidth
            separator: SeparatorState.HiddenSeparator
            key: Qt.Key_Multi_key
            caption: "+/-"
            text: "+-"
        }
    }

    Row {
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
        BackspaceKey {
            width: main.keyWidth
            height: geometry.keyHeightPortrait
            separator: false
        }
    }

    Row {
        x: main.keyWidth

        NumberKey {
            caption: "0"
            width: main.keyWidth
        }
        NumberKey {
            caption: Qt.locale().decimalPoint
            width: main.keyWidth
        }
        EnterKey {
            width: main.keyWidth
            height: geometry.keyHeightPortrait
            separator: false
        }
    }
}
