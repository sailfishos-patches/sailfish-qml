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
    type: "gujarati"
    capsLockSupported: false
    splitSupported: true

    KeyboardRow {
        SmallCharacterKey { caption: "ૌ"; captionShifted: "ઔ"; symView: "1"; symView2: "૧" }
        SmallCharacterKey { caption: "ૈ"; captionShifted: "ઐ"; symView: "2"; symView2: "૨" }
        SmallCharacterKey { caption: "ા"; captionShifted: "આ"; symView: "3"; symView2: "૩" }
        SmallCharacterKey { caption: "ી"; captionShifted: "ઈ"; symView: "4"; symView2: "૪" }
        SmallCharacterKey { caption: "ૂ"; captionShifted: "ઊ"; symView: "5"; symView2: "૫" }
        SmallCharacterKey { caption: "બ"; captionShifted: "ભ"; symView: "6"; symView2: "૬" }
        SmallCharacterKey { caption: "હ"; captionShifted: "ઙ"; symView: "7"; symView2: "૭" }
        SmallCharacterKey { caption: "ગ"; captionShifted: "ઘ"; symView: "8"; symView2: "૮" }
        SmallCharacterKey { caption: "દ"; captionShifted: "ધ"; symView: "9"; symView2: "૯" }
        SmallCharacterKey { caption: "જ"; captionShifted: "ઝ"; symView: "0"; symView2: "૦" }
        SmallCharacterKey { caption: "ડ"; captionShifted: "ઢ"; symView: "%"; symView2: "‰" }
    }
    KeyboardRow {
        SmallCharacterKey { caption: "ો"; captionShifted: "ઓ"; symView: "@"; symView2: "<" }
        SmallCharacterKey { caption: "ે"; captionShifted: "એ"; symView: "*"; symView2: ">" }
        SmallCharacterKey { caption: "્"; captionShifted: "અ"; symView: "#"; symView2: "«" }
        SmallCharacterKey { caption: "િ"; captionShifted: "ઇ"; symView: "+"; symView2: "»" }
        SmallCharacterKey { caption: "ુ"; captionShifted: "ઉ"; symView: "-"; symView2: "&" }
        SmallCharacterKey { caption: "પ"; captionShifted: "ફ"; symView: "="; symView2: "§" }
        SmallCharacterKey { caption: "ર"; captionShifted: "ર"; symView: "_"; symView2: "॥" }
        SmallCharacterKey { caption: "ક"; captionShifted: "ખ"; symView: "/"; symView2: "\\" }
        SmallCharacterKey { caption: "ત"; captionShifted: "થ"; symView: "("; symView2: "{" }
        SmallCharacterKey { caption: "ચ"; captionShifted: "છ"; symView: ")"; symView2: "}" }
        SmallCharacterKey { caption: "ટ"; captionShifted: "ઠ"; symView: "॰"; symView2: "ૐ" }
    }
    KeyboardRow {
        ShiftKey {}

        SmallCharacterKey { caption: "ૉ"; captionShifted: "ૃ"; symView: "\""; symView2: "઼" }
        SmallCharacterKey { caption: "ં"; captionShifted: "ઁ"; symView: "'"; symView2: "ઋ" }
        SmallCharacterKey { caption: "મ"; captionShifted: "ણ"; symView: ";"; symView2: "ૃ" }
        SmallCharacterKey { caption: "ન"; captionShifted: "ન"; symView: ":"; symView2: "ઍ" }
        SmallCharacterKey { caption: "વ"; captionShifted: "વ"; symView: "€"; symView2: "ઑ" }
        SmallCharacterKey { caption: "લ"; captionShifted: "ળ"; symView: "£"; symView2: "ૅ" }
        SmallCharacterKey { caption: "સ"; captionShifted: "શ"; symView: "$"; symView2: "ઞ" }
        SmallCharacterKey { caption: "ય"; captionShifted: "ઃ"; symView: "₹"; symView2: "૱" }

        BackspaceKey {}
    }
    KeyboardRow {
        splitIndex: 4

        SymbolKey {
            implicitWidth: symbolKeyWidthNarrow
            symbolCaption: "અઇ"
        }
        SmallCharacterKey {
            caption: "."
            captionShifted: "."
            symView: "."
            symView2: "."
            implicitWidth: punctuationKeyWidth
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
            implicitWidth: punctuationKeyWidth
            fixedWidth: !splitActive
            separator: SeparatorState.HiddenSeparator
        }
        EnterKey {}
    }
}
