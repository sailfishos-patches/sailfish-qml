import QtQuick 2.6
import com.jolla.keyboard 1.0

CharacterKey {
    property bool popupAlways: true // also in symbol view state
    caption: "."
    captionShifted: "."
    accents: "!.?"
    accentsShifted: "!.?"
    implicitWidth: punctuationKeyWidthNarrow
    fixedWidth: !splitActive
    separator: SeparatorState.HiddenSeparator
}
