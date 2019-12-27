/*
 * Copyright (C) 2016 Jolla ltd and/or its subsidiary(-ies). All rights reserved.
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
        CharacterKey { caption: ";"; captionShifted: ":"; symView: "1"; symView2: "€" }
        CharacterKey { caption: "ς"; captionShifted: "ς"; symView: "2"; symView2: "£" }
        AccentedCharacterKey {
            caption: "ε"; captionShifted: "Ε"
            symView: "3"; symView2: "$"
            accents: "έε€"; accentsShifted: "ΈΕ€"
            deadKeyAccents: "΄έ"; deadKeyAccentsShifted: "΄Έ"
        }
        CharacterKey { caption: "ρ"; captionShifted: "Ρ"; symView: "4"; symView2: "¥" }
        CharacterKey { caption: "τ"; captionShifted: "Τ"; symView: "5"; symView2: "₹" }
        AccentedCharacterKey {
            caption: "υ"; captionShifted: "Υ"
            symView: "6"; symView2: "%"
            accents: "ύυϋΰ"; accentsShifted: "ΎΥΫ"
            deadKeyAccents: "΄ύ"; deadKeyAccentsShifted: "΄Ύ"
        }
        CharacterKey { caption: "θ"; captionShifted: "Θ"; symView: "7"; symView2: "<" }
        AccentedCharacterKey {
            caption: "ι"; captionShifted: "Ι"
            symView: "8"; symView2: ">"
            accents: "ίιϊΐ"; accentsShifted: "ΊΙΪ"
            deadKeyAccents: "΄ί"; deadKeyAccentsShifted: "΄Ί"
        }
        AccentedCharacterKey {
            caption: "ο"; captionShifted: "Ο"; symView: "9"; symView2: "["; accents: "όο"; accentsShifted: "ΌΟ"
            deadKeyAccents: "΄ό"; deadKeyAccentsShifted: "΄Ό"
        }
        CharacterKey { caption: "π"; captionShifted: "Π"; symView: "0"; symView2: "]" }
    }

    KeyboardRow {
        splitIndex: 5

        AccentedCharacterKey {
            caption: "α"; captionShifted: "Α"
            symView: "*"; symView2: "`"
            accents: "αά"; accentsShifted: "ΑΆ"
            deadKeyAccents: "΄ά"; deadKeyAccentsShifted: "΄Ά"
        }
        CharacterKey { caption: "σ"; captionShifted: "Σ"; symView: "#"; symView2: "^" }
        CharacterKey { caption: "δ"; captionShifted: "Δ"; symView: "+"; symView2: "|" }
        CharacterKey { caption: "φ"; captionShifted: "Φ"; symView: "-"; symView2: "_" }
        CharacterKey { caption: "γ"; captionShifted: "Γ"; symView: "="; symView2: "§" }
        AccentedCharacterKey {
            caption: "η"; captionShifted: "Η"
            symView: "("; symView2: "{"
            accents: "ηή"; accentsShifted: "ΗΉ"
            deadKeyAccents: "΄ή"; deadKeyAccentsShifted: "΄Ή"
        }
        CharacterKey { caption: "ξ"; captionShifted: "Ξ"; symView: ")"; symView2: "}" }
        CharacterKey { caption: "κ"; captionShifted: "Κ"; symView: "!"; symView2: "¡" }
        CharacterKey { caption: "λ"; captionShifted: "Λ"; symView: "?"; symView2: "¿" }
        DeadKey {
            caption: "΄"
            captionShifted: "΄"
        }
    }

    KeyboardRow {
        splitIndex: 5

        ShiftKey {}

        CharacterKey { caption: "ζ"; captionShifted: "Ζ"; symView: "@"; symView2: "«" }
        CharacterKey { caption: "χ"; captionShifted: "Χ"; symView: "&"; symView2: "»" }
        CharacterKey { caption: "ψ"; captionShifted: "Ψ"; symView: "/"; symView2: "\"" }
        AccentedCharacterKey {
            caption: "ω"; captionShifted: "Ω"
            symView: "\\"; symView2: "“"
            accents: "ωώ"; accentsShifted: "ΩΏ"
            deadKeyAccents: "΄ώ"; deadKeyAccentsShifted: "΄Ώ"
        }
        CharacterKey { caption: "β"; captionShifted: "Β"; symView: "'"; symView2: "”" }
        CharacterKey { caption: "ν"; captionShifted: "Ν"; symView: ";"; symView2: "„" }
        CharacterKey { caption: "μ"; captionShifted: "Μ"; symView: ":"; symView2: "~" }

        BackspaceKey {}
    }

    KeyboardRow {
        splitIndex: 3

        SymbolKey {
            symbolCaption: "ΑΒΓ"
        }
        ContextAwareCommaKey {}
        SpacebarKey {}
        SpacebarKey {
            active: splitActive
            languageLabel: ""
        }
        CharacterKey {
            caption: "."
            captionShifted: "."
            implicitWidth: punctuationKeyWidth
            fixedWidth: !splitActive
            separator: SeparatorState.HiddenSeparator
        }
        EnterKey {}
    }
}
