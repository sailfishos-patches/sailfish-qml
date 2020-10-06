/*
 * Copyright (C) 2013 Jolla ltd and/or its subsidiary(-ies). All rights reserved.
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

KeyboardLayout {
    splitSupported: true

    KeyboardRow {
        CharacterKey { caption: "q"; captionShifted: "Q"; symView: "1"; symView2: "€" }
        CharacterKey { caption: "w"; captionShifted: "W"; symView: "2"; symView2: "£" }
        AccentedCharacterKey {
            caption: "e"
            captionShifted: "E"
            symView: "3"
            symView2: "$"
            accents: "ęeéě€"
            accentsShifted: "ĘEÉĚ€"
            deadKeyAccents: "´ę"
            deadKeyAccentsShifted: "´Ę"
        }

        CharacterKey { caption: "r"; captionShifted: "R"; symView: "4"; symView2: "¥"; accents: "ŕrř"; accentsShifted: "ŔRŘ" }
        CharacterKey { caption: "t"; captionShifted: "T"; symView: "5"; symView2: "₹"; accents: "ţtť"; accentsShifted: "ŢTŤ" }
        CharacterKey { caption: "y"; captionShifted: "Y"; symView: "6"; symView2: "%"; accents: "y¥"; accentsShifted: "Y¥" }
        CharacterKey { caption: "u"; captionShifted: "U"; symView: "7"; symView2: "<"; accents: "üúuůű"; accentsShifted: "ÜÚUŮŰ" }
        CharacterKey { caption: "i"; captionShifted: "I"; symView: "8"; symView2: ">"; accents: "íiî"; accentsShifted: "ÍIÎ" }
        AccentedCharacterKey {
            caption: "o"
            captionShifted: "O"
            symView: "9"
            symView2: "["
            accents: "óøöôoő"
            accentsShifted: "ÓØÖÔOŐ"
            deadKeyAccents: "´ó"
            deadKeyAccentsShifted: "´Ó"
        }
        CharacterKey { caption: "p"; captionShifted: "P"; symView: "0"; symView2: "]" }
    }

    KeyboardRow {
        splitIndex: 5

        AccentedCharacterKey {
            caption: "a"
            captionShifted: "A"
            symView: "*"
            symView2: "`"
            accents: "aąäáâă"
            accentsShifted: "AĄÄÁÂĂ"
            deadKeyAccents: "´ą"
            deadKeyAccentsShifted: "´Ą"
        }
        AccentedCharacterKey {
            caption: "s"
            captionShifted: "S"
            symView: "#"
            symView2: "^"
            accents: "sśßşš$"
            accentsShifted: "SŚẞŞŠ$"
            deadKeyAccents: "´ś"
            deadKeyAccentsShifted: "´Ś"
        }
        CharacterKey { caption: "d"; captionShifted: "D"; symView: "+"; symView2: "|"; accents: "ďdđ"; accentsShifted: "ĎDĐ" }
        CharacterKey { caption: "f"; captionShifted: "F"; symView: "-"; symView2: "_" }
        CharacterKey { caption: "g"; captionShifted: "G"; symView: "="; symView2: "§" }
        CharacterKey { caption: "h"; captionShifted: "H"; symView: "("; symView2: "{" }
        CharacterKey { caption: "j"; captionShifted: "J"; symView: ")"; symView2: "}" }
        CharacterKey { caption: "k"; captionShifted: "K"; symView: "!"; symView2: "¡" }
        AccentedCharacterKey {
            caption: "l"
            captionShifted: "L"
            symView: "?"
            symView2: "¿"
            accents: "łľĺl"
            accentsShifted: "ŁĽĹL"
            deadKeyAccents: "´ł"
            deadKeyAccentsShifted: "´Ł"
        }
    }

    KeyboardRow {
        splitIndex: 5

        ShiftKey {}

        AccentedCharacterKey {
            caption: "z"
            captionShifted: "Z"
            symView: "@"
            symView2: "«"
            accents: "żzźž"
            accentsShifted: "ŻZŹŽ"
            deadKeyAccents: "´ż"
            deadKeyAccentsShifted: "´Ż"
        }
        AccentedCharacterKey {
            caption: "x"
            captionShifted: "X"
            symView: "&"
            symView2: "»"
            deadKeyAccents: "´ź"
            deadKeyAccentsShifted: "´Ź"
        }
        AccentedCharacterKey {
            caption: "c"
            captionShifted: "C"
            symView: "/"
            symView2: "\""
            accents: "cćčç"
            accentsShifted: "CĆČÇ"
            deadKeyAccents: "´ć"
            deadKeyAccentsShifted: "´Ć"
        }
        CharacterKey { caption: "v"; captionShifted: "V"; symView: "\\"; symView2: "“" }
        CharacterKey { caption: "b"; captionShifted: "B"; symView: "'"; symView2: "”" }
        AccentedCharacterKey {
            caption: "n"
            captionShifted: "N"
            symView: ";"
            symView2: "„"
            accents: "ńňnñ"
            accentsShifted: "ŃŇNÑ"
            deadKeyAccents: "´ń"
            deadKeyAccentsShifted: "´Ń"
        }
        CharacterKey { caption: "m"; captionShifted: "M"; symView: ":"; symView2: "~" }

        BackspaceKey {}
    }

    SpacebarRowDeadKey {
        deadKeyCaption: "´"
        deadKeyCaptionShifted: "´"
    }
}
