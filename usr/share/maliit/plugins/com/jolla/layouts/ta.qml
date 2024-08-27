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
    type: "tamil"
    capsLockSupported: false
    splitSupported: true

    KeyboardRow {
        TinyCharacterKey { caption: "ௗ"; captionShifted: "ஔ"; symView: "1"; symView2: "௧" }
        TinyCharacterKey { caption: "ை"; captionShifted: "ஐ"; symView: "2"; symView2: "௨"}
        TinyCharacterKey { caption: "ா"; captionShifted: "ஆ"; symView: "3"; symView2: "௩" }
        TinyCharacterKey { caption: "ீ"; captionShifted: "ஈ"; symView: "4"; symView2: "௪" }
        TinyCharacterKey { caption: "ூ"; captionShifted: "ஊ"; symView: "5"; symView2: "௫" }
        TinyCharacterKey { caption: "ப"; captionShifted: "ப"; symView: "6"; symView2: "௬" }
        TinyCharacterKey { caption: "ஹ"; captionShifted: "ங"; symView: "7"; symView2: "௭" }
        TinyCharacterKey { caption: "க"; captionShifted: "க"; symView: "8"; symView2: "௮" }
        TinyCharacterKey { caption: "ஜ"; captionShifted: "ஷ"; symView: "9"; symView2: "௯" }
        TinyCharacterKey { caption: "ௌ"; captionShifted: "ௌ"; symView: "0"; symView2: "௦" }
    }
    KeyboardRow {
        TinyCharacterKey { caption: "ோ"; captionShifted: "ஓ"; symView: "@"; symView2: "<" }
        TinyCharacterKey { caption: "ே"; captionShifted: "ஏ"; symView: "*"; symView2: ">" }
        TinyCharacterKey { caption: "்"; captionShifted: "அ"; symView: "#"; symView2: "«" }
        TinyCharacterKey { caption: "ி"; captionShifted: "இ"; symView: "+"; symView2: "»" }
        TinyCharacterKey { caption: "ு"; captionShifted: "உ"; symView: "-"; symView2: "\"" }
        TinyCharacterKey { caption: "ப"; captionShifted: "ப"; symView: "="; symView2: "%" }
        TinyCharacterKey { caption: "ர"; captionShifted: "ற"; symView: "_"; symView2: "ௐ" }
        TinyCharacterKey { caption: "த"; captionShifted: "த"; symView: "/"; symView2: "\\" }
        TinyCharacterKey { caption: "ச"; captionShifted: "ச"; symView: "("; symView2: "{" }
        TinyCharacterKey { caption: "ட"; captionShifted: "ட"; symView: ")"; symView2: "}" }
    }
    KeyboardRow {
        ShiftKey {}

        TinyCharacterKey { caption: "ெ"; captionShifted: "ூ"; symView: "'"; symView2: "ொ" }
        TinyCharacterKey { caption: "ம"; captionShifted: "எ"; symView: ";"; symView2: "ஒ" }
        TinyCharacterKey { caption: "ந"; captionShifted: "ண"; symView: ":"; symView2: "ஶ" }
        TinyCharacterKey { caption: "வ"; captionShifted: "ன"; symView: "€"; symView2: "க்ஷ" }
        TinyCharacterKey { caption: "ல"; captionShifted: "ழ"; symView: "£"; symView2: "ஸ்ரீ" }
        TinyCharacterKey { caption: "ஸ"; captionShifted: "ள"; symView: "$"; symView2: "ஃ" }
        TinyCharacterKey { caption: "ஞ"; captionShifted: "ய"; symView: "₹"; symView2: "௹" }

        BackspaceKey {}
    }
    KeyboardRow {
        splitIndex: 4

        SymbolKey {
            implicitWidth: symbolKeyWidthNarrow
            symbolCaption: "அஇ"
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
