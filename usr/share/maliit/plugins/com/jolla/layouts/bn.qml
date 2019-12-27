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
    type: "bengali"
    capsLockSupported: false
    splitSupported: true

    KeyboardRow {
        SmallCharacterKey { caption: "ৌ"; captionShifted: "ঔ"; symView: "1"; symView2: "১" }
        SmallCharacterKey { caption: "ৈ"; captionShifted: "ঐ"; symView: "2"; symView2: "২"}
        SmallCharacterKey { caption: "া"; captionShifted: "আ"; symView: "3"; symView2: "৩" }
        SmallCharacterKey { caption: "ী"; captionShifted: "ঈ"; symView: "4"; symView2: "৪" }
        SmallCharacterKey { caption: "ূ"; captionShifted: "ঊ"; symView: "5"; symView2: "৫" }
        SmallCharacterKey { caption: "ব"; captionShifted: "ভ"; symView: "6"; symView2: "৬" }
        SmallCharacterKey { caption: "হ"; captionShifted: "ঙ"; symView: "7"; symView2: "৭" }
        SmallCharacterKey { caption: "গ"; captionShifted: "ঘ"; symView: "8"; symView2: "৮" }
        SmallCharacterKey { caption: "দ"; captionShifted: "ধ"; symView: "9"; symView2: "৯" }
        SmallCharacterKey { caption: "জ"; captionShifted: "ঝ"; symView: "0"; symView2: "০" }
        SmallCharacterKey { caption: "ড"; captionShifted: "ঢ"; symView: "%"; symView2: "‰" }
    }
    KeyboardRow {
        SmallCharacterKey { caption: "ো"; captionShifted: "ও"; symView: "@"; symView2: "<" }
        SmallCharacterKey { caption: "ে"; captionShifted: "এ"; symView: "*"; symView2: ">" }
        SmallCharacterKey { caption: "্"; captionShifted: "অ"; symView: "#"; symView2: "«" }
        SmallCharacterKey { caption: "ি"; captionShifted: "ই"; symView: "+"; symView2: "»" }
        SmallCharacterKey { caption: "ু"; captionShifted: "উ"; symView: "-"; symView2: "&" }
        SmallCharacterKey { caption: "প"; captionShifted: "ফ"; symView: "="; symView2: "§" }
        SmallCharacterKey { caption: "র"; captionShifted: "ঢ়"; symView: "_"; symView2: "॥" }
        SmallCharacterKey { caption: "ক"; captionShifted: "খ"; symView: "/"; symView2: "\\" }
        SmallCharacterKey { caption: "ত"; captionShifted: "থ"; symView: "("; symView2: "{" }
        SmallCharacterKey { caption: "চ"; captionShifted: "ছ"; symView: ")"; symView2: "}" }
        SmallCharacterKey { caption: "ট"; captionShifted: "ঠ"; symView: "॰"; symView2: "ॐ" }
    }
    KeyboardRow {
        ShiftKey {}

        SmallCharacterKey { caption: "ৎ"; captionShifted: "ঃ"; symView: "\""; symView2: "়" }
        SmallCharacterKey { caption: "ং"; captionShifted: "ঁ"; symView: "'"; symView2: "ৃ" }
        SmallCharacterKey { caption: "ম"; captionShifted: "ণ"; symView: ";"; symView2: "ত্র" }
        SmallCharacterKey { caption: "ন"; captionShifted: "ন"; symView: ":"; symView2: "ঞ" }
        SmallCharacterKey { caption: "ব"; captionShifted: "ব"; symView: "€"; symView2: "ড়" }
        SmallCharacterKey { caption: "ল"; captionShifted: "শ"; symView: "£"; symView2: "ঢ়" }
        SmallCharacterKey { caption: "স"; captionShifted: "ষ"; symView: "$"; symView2: "য়" }
        SmallCharacterKey { caption: "য়"; captionShifted: "য"; symView: "₹"; symView2: "ক্ষ" }

        BackspaceKey {}
    }
    KeyboardRow {
        splitIndex: 4

        SymbolKey {
            implicitWidth: symbolKeyWidthNarrow
            symbolCaption: "অআই"
        }
        SmallCharacterKey {
            caption: "."
            captionShifted: "."
            symView: "."
            symView2: "."
            implicitWidth: punctuationKeyWidthNarrow
            fixedWidth: !splitActive
        }
        SmallCharacterKey {
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
        SmallCharacterKey {
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
