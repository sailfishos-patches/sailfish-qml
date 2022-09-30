/*
 * Copyright (c) 2017 – 2022, Jolla Ltd
 * All rights reserved.
 *
 * Contact: Pekka Vuorela <pekka.vuorela@jolla.com>
 * Contact: Igerly <https://github.com/Igerly/jolla>
 * Contact: Simonas Leleiva <simonas.leleiva@jolla.com>
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
            accents: "èeēéêë€"
            accentsShifted: "ÈEĒÉÊË€"
            deadKeyAccents: "´ē"
            deadKeyAccentsShifted: "´Ē"
        }
        AccentedCharacterKey {
            caption: "r"
            captionShifted: "R"
            symView: "4"
            symView2: "—"
            accents: "ŗr"
            accentsShifted: "ŖR"
            deadKeyAccents: "´ŗ"
            deadKeyAccentsShifted: "´Ŗ"
        }
        CharacterKey { caption: "t"; captionShifted: "T"; symView: "5"; symView2: "±"; accents: "tþ"; accentsShifted: "TÞ" }
        CharacterKey { caption: "y"; captionShifted: "Y"; symView: "6"; symView2: "%"; accents: "ýy¥"; accentsShifted: "ÝY¥" }
        AccentedCharacterKey {
            caption: "u"
            captionShifted: "U"
            symView: "7"
            symView2: "<"
            accents: "űûùūuúü"
            accentsShifted: "ŰÛÙŪUÚÜ"
            deadKeyAccents: "´ū"
            deadKeyAccentsShifted: "´Ū"
        }
        AccentedCharacterKey {
            caption: "i"
            captionShifted: "I"
            symView: "8"
            symView2: ">"
            accents: "îïìīií"
            accentsShifted: "ĪÎÏÌĪIÍ"
            deadKeyAccents: "´ī"
            deadKeyAccentsShifted: "´Ī"
        }
        AccentedCharacterKey {
            caption: "o"
            captionShifted: "O"
            symView: "9"
            symView2: "["
            accents: "őøöôòōoó"
            accentsShifted: "ŐØÖÔÒŌOÓ"
            deadKeyAccents: "´ō"
            deadKeyAccentsShifted: "´Ō"
        }
        CharacterKey { caption: "p"; captionShifted: "P"; symView: "0"; symView2: "]" }
    }

    KeyboardRow {
        AccentedCharacterKey {
            caption: "a"
            captionShifted: "A"
            symView: "*"
            symView2: "`"
            accents: "aāäàâáãå"
            accentsShifted: "AĀÄÀÂÁÃÅ"
            deadKeyAccents: "´ā"
            deadKeyAccentsShifted: "´Ā"
        }
        AccentedCharacterKey {
            caption: "s"
            captionShifted: "S"
            symView: "#"
            symView2: "^"
            accents: "sšß$"
            accentsShifted: "SŠẞ$"
            deadKeyAccents: "´š"
            deadKeyAccentsShifted: "´Š"
        }
        CharacterKey { caption: "d"; captionShifted: "D"; symView: "+"; symView2: "|"; accents: "dð"; accentsShifted: "DÐ" }
        CharacterKey { caption: "f"; captionShifted: "F"; symView: "-"; symView2: "_" }
        AccentedCharacterKey {
            caption: "g"
            captionShifted: "G"
            symView: "="
            symView2: "§"
            accents: "ģg"
            accentsShifted: "ĢG"
            deadKeyAccents: "´ģ"
            deadKeyAccentsShifted: "´Ģ"
        }
        CharacterKey { caption: "h"; captionShifted: "H"; symView: "("; symView2: "{" }
        CharacterKey { caption: "j"; captionShifted: "J"; symView: ")"; symView2: "}" }
        AccentedCharacterKey {
            caption: "k"
            captionShifted: "K"
            symView: "!"
            symView2: "¡"
            accents: "kķ"
            accentsShifted: "KĶ"
            deadKeyAccents: "´ķ"
            deadKeyAccentsShifted: "´Ķ"
        }
        AccentedCharacterKey {
            caption: "l"
            captionShifted: "L"
            symView: "?"
            symView2: "¿"
            accents: "ļl"
            accentsShifted: "ĻL"
            deadKeyAccents: "´ļ"
            deadKeyAccentsShifted: "´Ļ"
        }
        DeadKey {
            caption: "´"
            captionShifted: "´"
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
            accents: "zž"
            accentsShifted: "ZŽ"
            deadKeyAccents: "´ž"
            deadKeyAccentsShifted: "´Ž"
        }

        CharacterKey { caption: "x"; captionShifted: "X"; symView: "&"; symView2: "»" }
        AccentedCharacterKey {
            caption: "c"
            captionShifted: "C"
            symView: "/"
            symView2: "\""
            accents: "čcç"
            accentsShifted: "ČCÇ"
            deadKeyAccents: "´č"
            deadKeyAccentsShifted: "´Č"
        }
        CharacterKey { caption: "v"; captionShifted: "V"; symView: "\\"; symView2: "“" }
        CharacterKey { caption: "b"; captionShifted: "B"; symView: "'"; symView2: "”" }

        AccentedCharacterKey {
            caption: "n"
            captionShifted: "N"
            symView: ";"
            symView2: "„"
            accents: "ņnñ"
            accentsShifted: "ŅNÑ"
            deadKeyAccents: "´ņ"
            deadKeyAccentsShifted: "´Ņ"
        }
        CharacterKey { caption: "m"; captionShifted: "M"; symView: ":"; symView2: "~" }

        BackspaceKey {}
    }

    SpacebarRow {}
}

