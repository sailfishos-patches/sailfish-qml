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
    type: "telugu"
    capsLockSupported: false
    splitSupported: true

    KeyboardRow {
        TinyCharacterKey { caption: "ౌ"; captionShifted: "ఔ"; symView: "1"; symView2: "౧" }
        TinyCharacterKey { caption: "ై"; captionShifted: "ఐ"; symView: "2"; symView2: "౨"}
        TinyCharacterKey { caption: "ా"; captionShifted: "ఆ"; symView: "3"; symView2: "౩" }
        TinyCharacterKey { caption: "ీ"; captionShifted: "ఈ"; symView: "4"; symView2: "౪" }
        TinyCharacterKey { caption: "ూ"; captionShifted: "ఊ"; symView: "5"; symView2: "౫" }
        TinyCharacterKey { caption: "బ"; captionShifted: "భ"; symView: "6"; symView2: "౬" }
        TinyCharacterKey { caption: "హ"; captionShifted: "ఙ"; symView: "7"; symView2: "౭" }
        TinyCharacterKey { caption: "గ"; captionShifted: "ఘ"; symView: "8"; symView2: "౮" }
        TinyCharacterKey { caption: "ద"; captionShifted: "ధ"; symView: "9"; symView2: "౯" }
        TinyCharacterKey { caption: "జ"; captionShifted: "ఝ"; symView: "0"; symView2: "౦" }
        TinyCharacterKey { caption: "డ"; captionShifted: "ఢ"; symView: "%"; symView2: "‰" }
    }
    KeyboardRow {
        TinyCharacterKey { caption: "ో"; captionShifted: "ఓ"; symView: "@"; symView2: "<" }
        TinyCharacterKey { caption: "ే"; captionShifted: "ఏ"; symView: "*"; symView2: ">" }
        TinyCharacterKey {
            // workaround Qt and Lohit issues, see Kannada layout
            caption: "్  "; captionShifted: "అ"; symView: "#"; symView2: "«"
            text: keyText.charAt(0)
        }
        TinyCharacterKey { caption: "ి"; captionShifted: "ఇ"; symView: "+"; symView2: "»" }
        TinyCharacterKey { caption: "ు"; captionShifted: "ఉ"; symView: "-"; symView2: "&" }
        TinyCharacterKey { caption: "ప"; captionShifted: "ఫ"; symView: "="; symView2: "§" }
        TinyCharacterKey { caption: "ర"; captionShifted: "ఱ"; symView: "_"; symView2: "॥" }
        TinyCharacterKey { caption: "క"; captionShifted: "ఖ"; symView: "/"; symView2: "\\" }
        TinyCharacterKey { caption: "త"; captionShifted: "థ"; symView: "("; symView2: "{" }
        TinyCharacterKey { caption: "చ"; captionShifted: "ఛ"; symView: ")"; symView2: "}" }
        TinyCharacterKey { caption: "ట"; captionShifted: "ఠ"; symView: "॰"; symView2: "ఒం" }
    }
    KeyboardRow {
        ShiftKey {}

        TinyCharacterKey { caption: "ె"; captionShifted: "ఎ"; symView: "\""; symView2: "ొ" }
        TinyCharacterKey { caption: "ం"; captionShifted: "ః"; symView: "'"; symView2: "ఒ" }
        TinyCharacterKey { caption: "మ"; captionShifted: "ణ"; symView: ";"; symView2: "ఞ" }
        TinyCharacterKey { caption: "న"; captionShifted: "ృ"; symView: ":"; symView2: "ఁ" }
        TinyCharacterKey { caption: "వ"; captionShifted: "ళ"; symView: "€"; symView2: "ఋ" }
        TinyCharacterKey { caption: "ల"; captionShifted: "ౕ"; symView: "£"; symView2: "ౠ" }
        TinyCharacterKey { caption: "స"; captionShifted: "శ"; symView: "$"; symView2: "ఌ" }
        TinyCharacterKey { caption: "య"; captionShifted: "ష"; symView: "₹"; symView2: "ౡ" }

        BackspaceKey {}
    }
    KeyboardRow {
        splitIndex: 4

        SymbolKey {
            implicitWidth: symbolKeyWidthNarrow
            symbolCaption: "అఆఇ"
        }
        TinyCharacterKey {
            caption: "."
            captionShifted: "."
            symView: "."
            symView2: "."
            implicitWidth: punctuationKeyWidthNarrow
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
            implicitWidth: punctuationKeyWidthNarrow
            fixedWidth: !splitActive
            separator: SeparatorState.HiddenSeparator
        }
        EnterKey {}
    }
}
