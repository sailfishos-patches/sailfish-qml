// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import com.jolla.keyboard 1.0
import ".."

KeyboardRow {
    id: spacebarRow

    property alias deadKeyCaption: deadKey.caption
    property alias deadKeyCaptionShifted: deadKey.captionShifted
    property alias periodAccents: periodKey.accents

    splitIndex: 4

    SymbolKey {
        implicitWidth: symbolKeyWidthNarrow
    }
    DeadKey {
        id: deadKey

        implicitWidth: punctuationKeyWidth
        fixedWidth: !splitActive
        separator: SeparatorState.HiddenSeparator
    }
    ContextAwareCommaKey {
        implicitWidth: punctuationKeyWidth
    }
    SpacebarKey {}
    SpacebarKey {
        active: splitActive
        languageLabel: ""
    }
    PeriodKey {
        id: periodKey

        accentsShifted: accents
        implicitWidth: punctuationKeyWidth
    }
    EnterKey {}
}
