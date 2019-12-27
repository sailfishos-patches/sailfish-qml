// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as SilicaPrivate

InputHandler {
    id: pasteHandler

    function formatText(text) {
        return Theme.highlightText(text, MInputMethodQuick.surroundingText, Theme.highlightColor)
    }

    onSelect: {
        MInputMethodQuick.sendCommit(text, -MInputMethodQuick.cursorPosition, MInputMethodQuick.surroundingText.length)
    }

    onRemove: {
        // We're using an unused key modifier flag as a back channel.
        MInputMethodQuick.sendKey(Qt.Key_Delete, 0x80000000, text)
    }

    onPaste: {
        MInputMethodQuick.sendCommit(Clipboard.text)
    }

    topItem: Component {
        TopItem {
            HorizontalPredictionListView {
                id: horizontalList

                handler: pasteHandler
                model: suggestionModel
                canRemove: !!MInputMethodQuick.extensions.autoFillCanRemove
                Connections {
                    target: suggestionModel
                    onStringsChanged: horizontalList.showRemoveButton = false
                    onKeyClick: horizontalList.showRemoveButton = false
                }
            }
        }
    }

    verticalItem: Component {
        Item {
            VerticalPredictionListView {
                id: verticalList

                handler: pasteHandler
                model: suggestionModel
                canRemove: !!MInputMethodQuick.extensions.autoFillCanRemove
                Connections {
                    target: suggestionModel
                    onStringsChanged: verticalList.showRemoveButton = false
                    onKeyClick: horizontalList.showRemoveButton = false
                }
            }
        }
    }

    SilicaPrivate.StringListModel {
        id: suggestionModel

        signal keyClick

        propertyName: "text"
        strings: MInputMethodQuick.extensions.autoFillSuggestions || []
    }

    function handleKeyClick() {
        keyboard.expandedPaste = false
        suggestionModel.keyClick()
        return false
    }
}
