/*
 * Copyright (C) 2017 Jolla ltd and/or its subsidiary(-ies). All rights reserved.
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
import ".."
import com.jolla.keyboard 1.0

KeyboardLayout {
    splitSupported: true

    KeyboardRow {
        CharacterKey { caption: "й"; captionShifted: "Й"; symView: "1"; symView2: "€" }
        CharacterKey { caption: "ө"; captionShifted: "Ө"; symView: "2"; symView2: "£" }
        CharacterKey { caption: "у"; captionShifted: "У"; symView: "3"; symView2: "$"; accents: "уў"; accentsShifted: "УЎ" }
        CharacterKey { caption: "к"; captionShifted: "К"; symView: "4"; symView2: "¥" }
        CharacterKey { caption: "е"; captionShifted: "Е"; symView: "5"; symView2: "₹"; accents: "ёе€"; accentsShifted: "ЁЕ€" }
        CharacterKey { caption: "н"; captionShifted: "Н"; symView: "6"; symView2: "₽" }
        CharacterKey { caption: "г"; captionShifted: "Г"; symView: "7"; symView2: "<" }
        CharacterKey { caption: "ш"; captionShifted: "Ш"; symView: "8"; symView2: ">"; accents: "шщ"; accentsShifted: "ШЩ" }
        CharacterKey { caption: "ә"; captionShifted: "Ә"; symView: "9"; symView2: "["; accents: "әэ"; accentsShifted: "ӘЭ" }
        CharacterKey { caption: "з"; captionShifted: "З"; symView: "0"; symView2: "]" }
        CharacterKey { caption: "һ"; captionShifted: "Һ"; symView: "№"; symView2: "¢" }
        FittedCharacterKey { caption: "ү"; captionShifted: "Ү"; symView: "%"; symView2: "‰" }
    }

    KeyboardRow {
        CharacterKey { caption: "ф"; captionShifted: "Ф"; symView: "*"; symView2: "`" }
        CharacterKey { caption: "ы"; captionShifted: "Ы"; symView: "#"; symView2: "√" }
        CharacterKey { caption: "в"; captionShifted: "В"; symView: "+"; symView2: "±" }
        CharacterKey { caption: "а"; captionShifted: "А"; symView: "×"; symView2: "_" }
        CharacterKey { caption: "п"; captionShifted: "П"; symView: "="; symView2: "≈" }
        CharacterKey { caption: "р"; captionShifted: "Р"; symView: "("; symView2: "{" }
        CharacterKey { caption: "о"; captionShifted: "О"; symView: ")"; symView2: "}" }
        CharacterKey { caption: "л"; captionShifted: "Л"; symView: "\""; symView2: "°" }
        CharacterKey { caption: "д"; captionShifted: "Д"; symView: "~"; symView2: "·" }
        CharacterKey { caption: "ң"; captionShifted: "Ң"; symView: "²"; symView2: "³" }
        CharacterKey { caption: "х"; captionShifted: "Х"; symView: "!"; symView2: "¡" }
        CharacterKey { caption: "ц"; captionShifted: "Ц"; symView: "?"; symView2: "¿" }
    }

    KeyboardRow {
        separateButtonSizes: true

        ShiftKey {
            implicitWidth: shiftKeyWidthNarrow
        }

        CharacterKey { caption: "я"; captionShifted: "Я"; symView: "@"; symView2: "«" }
        CharacterKey { caption: "ч"; captionShifted: "Ч"; symView: "&"; symView2: "»" }
        CharacterKey { caption: "с"; captionShifted: "С"; symView: "/"; symView2: "÷" }
        CharacterKey { caption: "м"; captionShifted: "М"; symView: "\\"; symView2: "“" }
        CharacterKey { caption: "и"; captionShifted: "И"; symView: "'"; symView2: "”" }
        CharacterKey { caption: "т"; captionShifted: "Т"; symView: ";"; symView2: "„" }
        CharacterKey { caption: "җ"; captionShifted: "Җ"; symView: ":"; symView2: "©"; accents: "җж"; accentsShifted: "ҖЖ" }
        CharacterKey { caption: "б"; captionShifted: "Б"; symView: "¼"; symView2: "½" }
        CharacterKey { caption: "ю"; captionShifted: "Ю"; symView: "^"; symView2: "®" }
        CharacterKey { caption: "ь"; captionShifted: "Ь"; symView: "|"; symView2: "§"; accents: "ьъ"; accentsShifted: "ЬЪ" }

        BackspaceKey {
            implicitWidth: shiftKeyWidthNarrow
        }
    }

    KeyboardRow {
        splitIndex: 4

        SymbolKey {
            symbolCaption: "АБВ"
            implicitWidth: symbolKeyWidthNarrow
        }

        CharacterKey {
            caption: "-"
            captionShifted: "-"
            implicitWidth: punctuationKeyWidth
            fixedWidth: !splitActive
        }
        ContextAwareCommaKey {
            implicitWidth: punctuationKeyWidth
        }
        SpacebarKey {}
        SpacebarKey {
            languageLabel: ""
            active: splitActive
        }
        PeriodKey {
            implicitWidth: punctuationKeyWidth
        }
        EnterKey {}
    }
}
