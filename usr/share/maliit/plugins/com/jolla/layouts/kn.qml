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
    type: "kannada"
    capsLockSupported: false
    splitSupported: true

    KeyboardRow {
        TinyCharacterKey {
            // HACK: workaround for Text.Fit not considering text beyond right side bearing, QTBUG-50642, JB#34093,
            // or alternatively Lohit glyphs having lot of content beyond the bearing,
            // https://github.com/pravins/lohit/issues/77 - see also Telugu layout
            caption: "ೌ  "; captionShifted: "ಔ"; symView: "1"; symView2: "೧"
            text: keyText.charAt(0)
        }
        TinyCharacterKey { caption: "ೈ"; captionShifted: "ಐ"; symView: "2"; symView2: "೨" }
        TinyCharacterKey {
            caption: "ಾ  "; captionShifted: "ಆ"; symView: "3"; symView2: "೩"
            text: keyText.charAt(0)
        }
        TinyCharacterKey { caption: "ೀ"; captionShifted: "ಈ"; symView: "4"; symView2: "೪" }
        TinyCharacterKey { caption: "ೂ"; captionShifted: "ಊ"; symView: "5"; symView2: "೫" }
        TinyCharacterKey { caption: "ಬ"; captionShifted: "ಭ"; symView: "6"; symView2: "೬" }
        TinyCharacterKey { caption: "ಹ"; captionShifted: "ಙ"; symView: "7"; symView2: "೭" }
        TinyCharacterKey { caption: "ಗ"; captionShifted: "ಘ"; symView: "8"; symView2: "೮" }
        TinyCharacterKey { caption: "ದ"; captionShifted: "ಧ"; symView: "9"; symView2: "೯" }
        TinyCharacterKey { caption: "ಜ"; captionShifted: "ಝ"; symView: "0"; symView2: "೦" }
        TinyCharacterKey { caption: "ಡ"; captionShifted: "ಢ"; symView: "%"; symView2: "‰" }
    }
    KeyboardRow {
        TinyCharacterKey { caption: "ೋ"; captionShifted: "ಓ"; symView: "@"; symView2: "<" }
        TinyCharacterKey { caption: "ೇ"; captionShifted: "ಏ"; symView: "*"; symView2: ">" }
        TinyCharacterKey {
            caption: "್  "; captionShifted: "ಅ"; symView: "#"; symView2: "«"
            text: keyText.charAt(0)
        }
        TinyCharacterKey { caption: "ಿ"; captionShifted: "ಇ"; symView: "+"; symView2: "»" }
        TinyCharacterKey { caption: "ು"; captionShifted: "ಉ"; symView: "-"; symView2: "&" }
        TinyCharacterKey { caption: "ಪ"; captionShifted: "ಫ"; symView: "="; symView2: "§" }
        TinyCharacterKey { caption: "ರ"; captionShifted: "ಱ"; symView: "_"; symView2: "॥" }
        TinyCharacterKey { caption: "ಕ"; captionShifted: "ಖ"; symView: "/"; symView2: "\\" }
        TinyCharacterKey { caption: "ತ"; captionShifted: "ಥ"; symView: "("; symView2: "{" }
        TinyCharacterKey { caption: "ಚ"; captionShifted: "ಛ"; symView: ")"; symView2: "}" }
        TinyCharacterKey { caption: "ಟ"; captionShifted: "ಠ"; symView: "॰"; symView2: "ಓಂ" }
    }
    KeyboardRow {
        ShiftKey {}

        TinyCharacterKey { caption: "ೆ"; captionShifted: "ಎ"; symView: "\""; symView2: "ೊ" }
        TinyCharacterKey { caption: "ಂ"; captionShifted: "ಃ"; symView: "'"; symView2: "ಒ" }
        TinyCharacterKey { caption: "ಮ"; captionShifted: "ಣ"; symView: ";"; symView2: "ಞ" }
        TinyCharacterKey { caption: "ನ"; captionShifted: "ೃ"; symView: ":"; symView2: "ಋ" }
        TinyCharacterKey { caption: "ವ"; captionShifted: "ಳ"; symView: "€"; symView2: "ೠ" }
        TinyCharacterKey { caption: "ಲ"; captionShifted: "ೕ"; symView: "£"; symView2: "ಌ" }
        TinyCharacterKey { caption: "ಸ"; captionShifted: "ಶ"; symView: "$"; symView2: "ೡ" }
        TinyCharacterKey { caption: "ಯ"; captionShifted: "ಷ"; symView: "₹"; symView2: "ೖ" }

        BackspaceKey {}
    }
    KeyboardRow {
        splitIndex: 4

        SymbolKey {
            implicitWidth: symbolKeyWidthNarrow
            symbolCaption: "ಅಆಇ"
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
