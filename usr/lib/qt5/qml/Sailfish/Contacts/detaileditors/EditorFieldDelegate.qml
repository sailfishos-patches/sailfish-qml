/*
 * Copyright (c) 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

StringDetailEntry {
    id: root

    property var editor
    property bool exitButtonModeWhenClicked: true
    property var _nextItemToFocus

    suggestions: editor && editor.suggestions

    width: parent.width
    value: model.value
    placeholderText: model.name
    detailSubType: model.subType === undefined ? -1 : model.subType
    detailLabel: model.label === undefined ? -1 : model.label
    inputMethodHints: model.inputMethodHints === undefined
                      ? root.inputMethodHints
                      : model.inputMethodHints

    animate: !!editor && editor.ready
    buttonModeText: !!editor ? editor.fieldAdditionText : ""
    buttonMode: buttonModeText.length > 0 && value.length === 0
                && editor && model.index === editor.detailModel.count-1
    activeFocusOnTab: !buttonMode

    onModified: {
        if (!!editor) {
            editor.detailModel.userModified = true
        }
    }

    onHasFocusChanged: {
        if (hasFocus) {
            _nextItemToFocus = pageStack.currentPage.findNextItemInFocusChain(root)
            keyboardEnterIcon = !!_nextItemToFocus
                    ? "image://theme/icon-m-enter-next"
                    : "image://theme/icon-m-enter-close"
        }
    }

    onAccepted: {
        if (!!_nextItemToFocus) {
            _nextItemToFocus.forceActiveFocus()
        } else {
            focus = true
        }
    }

    onRemoveClicked: {
        if (!!editor) {
            editor.detailModel.userModified = true
        }
    }

    onDetailSubTypeModified: {
        if (!!editor) {
            editor.detailModel.userModified = true
        }
    }

    onDetailLabelModified: {
        if (!!editor) {
            editor.detailModel.userModified = true
        }
    }

    onButtonModeChanged: {
        if (!buttonMode && editor && editor.ready) {
            forceActiveFocus(animationDuration)
        }
    }

    onEnteredButtonMode: {
        if (editor && editor.resetField !== undefined) {
            editor.resetField(model.index)
        }
    }

    onClickedInButtonMode: {
        if (buttonMode && exitButtonModeWhenClicked) {
            buttonMode = false
        }
    }
}
