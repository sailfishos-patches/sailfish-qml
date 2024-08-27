/*
 * Copyright (C) 2015 Jolla ltd and/or its subsidiary(-ies). All rights reserved.
 *
 * Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list
 * of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list
 * of conditions and the following disclaimer in the documentation and/or other materials
 * provided with the distribution.
 * Neither the name of Jolla Ltd nor the names of its contributors may be
 * used to endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

import QtQuick 2.0
import com.jolla.keyboard 1.0
import ".."

// Note: identical to hindi layout
KeyboardLayout {
    type: "marathi"
    capsLockSupported: false
    splitSupported: true

    property string base: "" // TODO: follow if last character should change key content

    KeyboardRow {
        DiaCharacterKey { caption: base + "ौ"; captionShifted: "औ"; symView: "1"; symView2: "१" }
        DiaCharacterKey { caption: base + "ै"; captionShifted: "ऐ"; symView: "2"; symView2: "२"}
        DiaCharacterKey { caption: base + "ा"; captionShifted: "आ"; symView: "3"; symView2: "३" }
        DiaCharacterKey { caption: base + "ी"; captionShifted: "ई"; symView: "4"; symView2: "४" }
        DiaCharacterKey { caption: base + "ू"; captionShifted: "ऊ"; symView: "5"; symView2: "५"}
        DiaCharacterKey { caption: "ब"; captionShifted: "भ"; symView: "6"; symView2: "६" }
        DiaCharacterKey { caption: "ह"; captionShifted: "ङ"; symView: "7"; symView2: "७" }
        DiaCharacterKey { caption: "ग"; captionShifted: "घ"; symView: "8"; symView2: "८" }
        DiaCharacterKey { caption: "द"; captionShifted: "ध"; symView: "9"; symView2: "९" }
        DiaCharacterKey { caption: "ज"; captionShifted: "झ"; symView: "0"; symView2: "०" }
        DiaCharacterKey { caption: "ड"; captionShifted: "ढ"; symView: "%"; symView2: "‰"; fontSizeMode: Text.HorizontalFit }
    }
    KeyboardRow {
        DiaCharacterKey { caption: base + "ो"; captionShifted: "ओ"; symView: "@"; symView2: "<" }
        DiaCharacterKey { caption: base + "े"; captionShifted: "ए"; symView: "*"; symView2: ">" }
        DiaCharacterKey { caption: base + "्"; captionShifted: "अ"; symView: "#"; symView2: "«" }
        DiaCharacterKey { caption: base + "ि"; captionShifted: "इ"; symView: "+"; symView2: "»"
            onWidthChanged: {
                // horrible hack. qml for some reason fails to apply centering on this when first shown.
                // forcing it for now
                var tmp = caption
                caption = ""
                caption = tmp
            }
        }
        DiaCharacterKey { caption: base + "ु"; captionShifted: "उ"; symView: "-"; symView2: "&" }
        DiaCharacterKey { caption: "प"; captionShifted: "फ"; symView: "="; symView2: "§" }
        DiaCharacterKey { caption: "र"; captionShifted: base + "ृ"; symView: "_"; symView2: "॥" }
        DiaCharacterKey { caption: "क"; captionShifted: "ख"; symView: "/"; symView2: "\\" }
        DiaCharacterKey { caption: "त"; captionShifted: "थ"; symView: "("; symView2: "{" }
        DiaCharacterKey { caption: "च"; captionShifted: "छ"; symView: ")"; symView2: "}" }
        DiaCharacterKey { caption: "ट"; captionShifted: "ठ"; symView: "॰"; symView2: "ॐ" }
    }

    KeyboardRow {
        ShiftKey {}

        DiaCharacterKey { caption: base + "ं"; captionShifted: base + "ँ"; symView: "\""; symView2: "ज्ञ" }
        DiaCharacterKey { caption: "म"; captionShifted: "ऍ"; symView: "'"; symView2: "त्र" }
        DiaCharacterKey { caption: "न"; captionShifted: "ण"; symView: ";"; symView2: "क्ष" }
        DiaCharacterKey { caption: "व"; captionShifted: base + "ॅ"; symView: ":"; symView2: "श्र" }
        DiaCharacterKey { caption: "ल"; captionShifted: "ळ"; symView: "€"; symView2: "ऋ" }
        DiaCharacterKey { caption: "स"; captionShifted: "श"; symView: "£"; symView2: "ञ" }
        DiaCharacterKey { caption: "य"; captionShifted: "ष"; symView: "$"; symView2: "ऑ" }
        DiaCharacterKey { caption: base + "़"; captionShifted: base + "ः"; symView: "₹"; symView2: base + "ॉ" }

        BackspaceKey {}
    }

    KeyboardRow {
        splitIndex: 4

        SymbolKey {
            implicitWidth: symbolKeyWidthNarrow
            symbolCaption: "अआइ"
        }
        DiaCharacterKey {
            caption: "."
            captionShifted: "."
            symView: "."
            symView2: "."
            implicitWidth: punctuationKeyWidth
            fixedWidth: !splitActive
        }
        DiaCharacterKey {
            caption: "।"
            captionShifted: "।"
            symView: ","
            symView2: ","
            separator: SeparatorState.HiddenSeparator
        }

        SpacebarKey {}
        SpacebarKey {
            active: splitActive
            languageLabel: ""
        }
        DiaCharacterKey {
            caption: "?"
            captionShifted: "?"
            symView: "!"
            symView2: "!"
            implicitWidth: punctuationKeyWidth
            fixedWidth: !splitActive
            separator: SeparatorState.HiddenSeparator
        }
        EnterKey {}
    }
}
