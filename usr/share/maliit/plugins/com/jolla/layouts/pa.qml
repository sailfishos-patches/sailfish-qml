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
    type: "punjabi"
    capsLockSupported: false
    splitSupported: true

    KeyboardRow {
        SmallCharacterKey { caption: "ੌ"; captionShifted: "ਔ"; symView: "1"; symView2: "੧" }
        SmallCharacterKey { caption: "ੈ"; captionShifted: "ਐ"; symView: "2"; symView2: "੨"}
        SmallCharacterKey { caption: "ਾ"; captionShifted: "ਆ"; symView: "3"; symView2: "੩" }
        SmallCharacterKey { caption: "ੀ"; captionShifted: "ਈ"; symView: "4"; symView2: "੪" }
        SmallCharacterKey { caption: "ੂ"; captionShifted: "ਊ"; symView: "5"; symView2: "੫" }
        SmallCharacterKey { caption: "ਬ"; captionShifted: "ਭ"; symView: "6"; symView2: "੬" }
        SmallCharacterKey { caption: "ਹ"; captionShifted: "ਙ"; symView: "7"; symView2: "੭" }
        SmallCharacterKey { caption: "ਗ"; captionShifted: "ਘ"; symView: "8"; symView2: "੮" }
        SmallCharacterKey { caption: "ਦ"; captionShifted: "ਧ"; symView: "9"; symView2: "੯" }
        SmallCharacterKey { caption: "ਜ"; captionShifted: "ਝ"; symView: "0"; symView2: "੦" }
        SmallCharacterKey { caption: "ਡ"; captionShifted: "ਢ"; symView: "%"; symView2: "‰" }
    }
    KeyboardRow {
        SmallCharacterKey { caption: "ੋ"; captionShifted: "ਓ"; symView: "@"; symView2: "<" }
        SmallCharacterKey { caption: "ੇ"; captionShifted: "ਏ"; symView: "*"; symView2: ">" }
        SmallCharacterKey { caption: "੍"; captionShifted: "ਅ"; symView: "#"; symView2: "«" }
        SmallCharacterKey { caption: "ਿ"; captionShifted: "ਇ"; symView: "+"; symView2: "»" }
        SmallCharacterKey { caption: "ੁ"; captionShifted: "ਉ"; symView: "-"; symView2: "&" }
        SmallCharacterKey { caption: "ਪ"; captionShifted: "ਫ"; symView: "="; symView2: "§" }
        SmallCharacterKey { caption: "ਰ"; captionShifted: "ਰ"; symView: "_"; symView2: "॥" }
        SmallCharacterKey { caption: "ਕ"; captionShifted: "ਖ"; symView: "/"; symView2: "\\" }
        SmallCharacterKey { caption: "ਤ"; captionShifted: "ਥ"; symView: "("; symView2: "{" }
        SmallCharacterKey { caption: "ਚ"; captionShifted: "ਛ"; symView: ")"; symView2: "}" }
        SmallCharacterKey { caption: "ਟ"; captionShifted: "ਠ"; symView: "॰"; symView2: "ੴ" }
    }
    KeyboardRow {
        ShiftKey {}

        SmallCharacterKey { caption: "ਂ"; captionShifted: "ਁ"; symView: "\""; symView2: "ਗ਼" }
        SmallCharacterKey { caption: "ਮ"; captionShifted: "ੰ"; symView: "'"; symView2: "ਜ਼" }
        SmallCharacterKey { caption: "ਨ"; captionShifted: "ਣ"; symView: ";"; symView2: "ੜ" }
        SmallCharacterKey { caption: "ਵ"; captionShifted: "ੲ"; symView: ":"; symView2: "ਫ਼" }
        SmallCharacterKey { caption: "ਲ"; captionShifted: "ਲ਼"; symView: "€"; symView2: "ਖ਼" }
        SmallCharacterKey { caption: "ਸ"; captionShifted: "ਸ਼"; symView: "£"; symView2: "ੳ" }
        SmallCharacterKey { caption: "ਯ"; captionShifted: "ਞ"; symView: "$"; symView2: "ੰ" }
        SmallCharacterKey { caption: "਼"; captionShifted: "ੱ"; symView: "₹"; symView2: "ਃ" }

        BackspaceKey {}
    }
    KeyboardRow {
        splitIndex: 4

        SymbolKey {
            implicitWidth: symbolKeyWidthNarrow
            symbolCaption: "ਅਇ"
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
