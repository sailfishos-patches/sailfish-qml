/*
 * LT-ąžerty keyboard modified from Jolla's EN keyboard.
 * Copyright (c) 2014 – 2020, Jolla Ltd.
 * All rights reserved.
 *
 * Contact: Pekka Vuorela <pekka.vuorela@jolla.com>
 * Contact: Tadas Krasauskas <tadas.krasauskas@gmail.com>
 * Contact: Simonas Leleiva <simonas.leleiva@jolla.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the Jolla Ltd. nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL JOLLA LTD. BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

import QtQuick 2.0
import ".."

KeyboardLayout {
    splitSupported: true

    KeyboardRow {
        CharacterKey { caption: "ą"; captionShifted: "Ą"; symView: "1"; symView2: "€"; accents: "ąqą́ą̃"; accentsShifted: "ĄQĄ́Ą̃" }
        CharacterKey { caption: "ž"; captionShifted: "Ž"; symView: "2"; symView2: "£"; accents: "žw"; accentsShifted: "ŽW" }
        CharacterKey { caption: "e"; captionShifted: "E"; symView: "3"; symView2: "$"; accents: "èeéẽ"; accentsShifted: "ÈEÉẼ" }
        CharacterKey { caption: "r"; captionShifted: "R"; symView: "4"; symView2: "¥"; accents: "rr̃"; accentsShifted: "RR̃" }
        CharacterKey { caption: "t"; captionShifted: "T"; symView: "5"; symView2: "₹" }
        CharacterKey { caption: "y"; captionShifted: "Y"; symView: "6"; symView2: "†"; accents: "ỹyý"; accentsShifted: "ỸYÝ" }
        CharacterKey { caption: "u"; captionShifted: "U"; symView: "7"; symView2: "<"; accents: "ũùuú"; accentsShifted: "ŨÙUÚ" }
        CharacterKey { caption: "i"; captionShifted: "I"; symView: "8"; symView2: ">"; accents: "ĩìií"; accentsShifted: "ĨÌIÍ" }
        CharacterKey { caption: "o"; captionShifted: "O"; symView: "9"; symView2: "["; accents: "õòoó"; accentsShifted: "ÕÒOÓ" }
        CharacterKey { caption: "p"; captionShifted: "P"; symView: "0"; symView2: "]" }
        CharacterKey { caption: "į"; captionShifted: "Į"; symView: "–"; symView2: "×"; accents: "į̃įį́"; accentsShifted: "Į̃ĮĮ́" }
        CharacterKey { caption: "ę"; captionShifted: "Ę"; symView: "%"; symView2: "‰"; accents: "ę̃ę"; accentsShifted: "Ę̃Ę" }
    }

    KeyboardRow {
        CharacterKey { caption: "a"; captionShifted: "A"; symView: "*"; symView2: "`"; accents: "aàáã"; accentsShifted: "AÀÁÃ" }
        CharacterKey { caption: "s"; captionShifted: "S"; symView: "#"; symView2: "√" }
        CharacterKey { caption: "d"; captionShifted: "D"; symView: "+"; symView2: "±" }
        CharacterKey { caption: "š"; captionShifted: "Š"; symView: "-"; symView2: "_" }
        CharacterKey { caption: "g"; captionShifted: "G"; symView: "="; symView2: "≈" }
        CharacterKey { caption: "h"; captionShifted: "H"; symView: "("; symView2: "{" }
        CharacterKey { caption: "j"; captionShifted: "J"; symView: ")"; symView2: "}" }
        CharacterKey { caption: "k"; captionShifted: "K"; symView: "„"; symView2: "°" }
        CharacterKey { caption: "l"; captionShifted: "L"; symView: "“"; symView2: "·"; accents: "l̃l"; accentsShifted: "L̃L" }
        CharacterKey { caption: "ų"; captionShifted: "Ų"; symView: "!"; symView2: "¡"; accents: "ų̃ų"; accentsShifted: "Ų̃Ų" }
        CharacterKey { caption: "ė"; captionShifted: "Ė"; symView: "?"; symView2: "¿"; accents: "ė́ė̃ė"; accentsShifted: "Ė́Ė̃Ė" }
    }

    KeyboardRow {
        splitIndex: 6

        ShiftKey {
            implicitWidth: shiftKeyWidthNarrow
        }

        CharacterKey { caption: "z"; captionShifted: "Z"; symView: "@"; symView2: "«" }
        CharacterKey { caption: "ū"; captionShifted: "Ū"; symView: "&"; symView2: "»"; accents: "ūxū́ū̃"; accentsShifted: "ŪXŪ́Ū̃" }
        CharacterKey { caption: "c"; captionShifted: "C"; symView: "/"; symView2: "÷" }
        CharacterKey { caption: "v"; captionShifted: "V"; symView: "\\"; symView2: "”" }
        CharacterKey { caption: "b"; captionShifted: "B"; symView: "'"; symView2: "\"" }
        CharacterKey { caption: "n"; captionShifted: "N"; symView: ";"; symView2: "§"; accents: "ñn"; accentsShifted: "ÑN" }
        CharacterKey { caption: "m"; captionShifted: "M"; symView: ":"; symView2: "~"; accents: "m̃m"; accentsShifted: "M̃M" }
        CharacterKey { caption: "č"; captionShifted: "Č"; symView: "^"; symView2: "©" }
        CharacterKey { caption: "f"; captionShifted: "F"; symView: "|"; symView2: "™" }

        BackspaceKey {
            implicitWidth: shiftKeyWidthNarrow
        }
    }

    SpacebarRow {}
}
