// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0 as Silica
import com.jolla.keyboard 1.0

KeyboardLayout {
    id: main

    property real keyWidth: width / 10

    layoutIndex: -1
    type: ""
    handler: null
    languageCode: ""

    Row {
        CharacterKey {
            caption: "1"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            showPopper: false
        }
        PhoneKey {
            caption: "2"
            secondaryLabel: "abc"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            landscape: true
        }
        PhoneKey {
            caption: "3"
            secondaryLabel: "def"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            landscape: true
        }
        PhoneKey {
            caption: "4"
            secondaryLabel: "ghi"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            landscape: true
        }
        PhoneKey {
            caption: "5"
            secondaryLabel: "jkl"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            landscape: true
        }
        PhoneKey {
            caption: "6"
            secondaryLabel: "mno"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            landscape: true
        }
        PhoneKey {
            caption: "7"
            secondaryLabel: "pqrs"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            landscape: true
        }
        PhoneKey {
            caption: "8"
            secondaryLabel: "tuv"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            landscape: true
        }
        PhoneKey {
            caption: "9"
            secondaryLabel: "wxyz"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            landscape: true
        }
        CharacterKey {
            caption: "0"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            showPopper: false
            separator: SeparatorState.HiddenSeparator
        }
    }

    Row {
        x: 3 * main.keyWidth

        NumberKey {
            width: main.keyWidth
            enabled: keyboard.pasteEnabled
            key: Qt.Key_Paste
            opacity: enabled ? (pressed ? 0.6 : 1.0)
                             : 0.3
            Silica.Icon {
                anchors.centerIn: parent
                source: "image://theme/icon-m-clipboard"
            }
        }
        CharacterKey {
            key: Qt.Key_Multi_key
            text: "*p"
            caption: "*p"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            showPopper: false
        }
        CharacterKey {
            caption: "+"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            showPopper: false
        }
        CharacterKey {
            caption: "#"
            height: geometry.keyHeightPortrait
            width: main.keyWidth
            showPopper: false
            separator: SeparatorState.HiddenSeparator
        }
        BackspaceKey {
            width: main.keyWidth
            height: geometry.keyHeightPortrait
        }
        EnterKey {
            width: main.width / 5
            height: geometry.keyHeightPortrait
        }
    }
}
