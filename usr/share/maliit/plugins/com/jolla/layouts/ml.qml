/*
 * Copyright (C) 2016 Jolla ltd and/or its subsiry(-ies). All rights reserved.
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

KeyboardLayout {
    type: "malayalam"
    capsLockSupported: false
    splitSupported: true

    KeyboardRow {
        TinyCharacterKey { caption: "ൌ"; captionShifted: "ഔ"; symView: "1"; symView2: "൧" }
        TinyCharacterKey { caption: "ൈ"; captionShifted: "ഐ"; symView: "2"; symView2: "൨" }
        TinyCharacterKey { caption: "ാ"; captionShifted: "ആ"; symView: "3"; symView2: "൩" }
        TinyCharacterKey { caption: "ീ"; captionShifted: "ഈ"; symView: "4"; symView2: "൪" }
        TinyCharacterKey { caption: "ൂ"; captionShifted: "ഊ"; symView: "5"; symView2: "൫" }
        TinyCharacterKey { caption: "ബ"; captionShifted: "ഭ"; symView: "6"; symView2: "൬" }
        TinyCharacterKey { caption: "ഹ"; captionShifted: "ങ"; symView: "7"; symView2: "൭" }
        TinyCharacterKey { caption: "ഗ"; captionShifted: "ഘ"; symView: "8"; symView2: "൮" }
        TinyCharacterKey { caption: "ദ"; captionShifted: "ധ"; symView: "9"; symView2: "൯" }
        TinyCharacterKey { caption: "ജ"; captionShifted: "ഝ"; symView: "0"; symView2: "൦" }
        TinyCharacterKey { caption: "ഡ"; captionShifted: "ഢ"; symView: "%"; symView2: "‰" }
    }
    KeyboardRow {
        TinyCharacterKey { caption: "ോ"; captionShifted: "ഓ"; symView: "@"; symView2: "<" }
        TinyCharacterKey { caption: "േ"; captionShifted: "ഏ"; symView: "*"; symView2: ">" }
        TinyCharacterKey { caption: "്"; captionShifted: "അ"; symView: "#"; symView2: "«" }
        TinyCharacterKey { caption: "ി"; captionShifted: "ഇ"; symView: "+"; symView2: "»" }
        TinyCharacterKey { caption: "ു"; captionShifted: "ഉ"; symView: "-"; symView2: "&" }
        TinyCharacterKey { caption: "പ"; captionShifted: "ഫ"; symView: "="; symView2: "§" }
        TinyCharacterKey { caption: "ര"; captionShifted: "റ"; symView: "_"; symView2: "॥" }
        TinyCharacterKey { caption: "ക"; captionShifted: "ഖ"; symView: "/"; symView2: "\\" }
        TinyCharacterKey { caption: "ത"; captionShifted: "ഥ"; symView: "("; symView2: "{" }
        TinyCharacterKey { caption: "ച"; captionShifted: "ഛ"; symView: ")"; symView2: "}" }
        TinyCharacterKey { caption: "ട"; captionShifted: "ഠ"; symView: "॰"; symView2: "ഃ" }
    }
    KeyboardRow {
        ShiftKey {}

        TinyCharacterKey { caption: "െ"; captionShifted: "എ"; symView: "\""; symView2: "ൊ" }
        TinyCharacterKey { caption: "ം"; captionShifted: "ൃ"; symView: "'"; symView2: "ഒ" }
        TinyCharacterKey { caption: "മ"; captionShifted: "ണ"; symView: ";"; symView2: "ന്‍" }
        TinyCharacterKey { caption: "ന"; captionShifted: "ഞ"; symView: ":"; symView2: "ണ്‍" }
        TinyCharacterKey { caption: "വ"; captionShifted: "ഴ"; symView: "€"; symView2: "ല്‍" }
        TinyCharacterKey { caption: "ല"; captionShifted: "ള"; symView: "£"; symView2: "ള്‍" }
        TinyCharacterKey { caption: "സ"; captionShifted: "ശ"; symView: "$"; symView2: "ര്‍" }
        TinyCharacterKey { caption: "യ"; captionShifted: "ഷ"; symView: "₹"; symView2: "ഋ" }

        BackspaceKey {}
    }
    KeyboardRow {
        splitIndex: 4

        SymbolKey {
            implicitWidth: symbolKeyWidthNarrow
            symbolCaption: "അഇ"
        }
        TinyCharacterKey {
            caption: "."
            captionShifted: "."
            symView: "."
            symView2: "."
            implicitWidth: punctuationKeyWidth
            fixedWidth: !splitActive
        }
        TinyCharacterKey {
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
        TinyCharacterKey {
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
